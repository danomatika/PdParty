/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PureData.h"

#import "PdAudioController.h"
#import "AppDelegate.h"
#import "Log.h"
#import "Osc.h"
#import "Sensors.h"
#import "Controllers.h"
#import "Externals.h"
#import "Util.h"

// for find functionality
#import "m_pd.h"
#import "g_canvas.h"

@interface PureData () {
	PdAudioController *audioController;
	PdFile *playbackPatch;
	CADisplayLink *updateLink;
	id routeChangeObserver; ///< opaque route change notification handle
}
@property (assign, readwrite, getter=isRecording, nonatomic) BOOL recording;
@end

@implementation PureData

- (id)init {
	self = [super init];
	if(self) {
		NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
		_autoLatency = [defaults floatForKey:@"autoLatency"];
		_micVolume = [defaults floatForKey:@"micVolume"];
		_volume = 1.0;
		_playing = YES;
		_recording = NO;

		// set PlayAndRecord category so number of inputs will not be 0 when calling
		// AVAUdioSession.sharedInstance.inputNumberOfChannels the first time
		[AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
		[AVAudioSession.sharedInstance setActive:YES error:nil];

		// configure a typical audio session with the current # of i/o channels
		audioController = [[PdAudioController alloc] init];
		audioController.mixWithOthers = YES;
		audioController.preferStereo = YES;
		audioController.allowBluetoothA2DP = YES;
		audioController.allowAirPlay = YES;
		audioController.defaultToSpeaker = ![defaults boolForKey:@"earpieceSpeakerEnabled"];
		self.sampleRate = (int)[defaults integerForKey:@"sampleRate"]; ///< audio unit set up here
		if(logLevel >= LogLevelVerbose) {
			[audioController print];
		}

		// set dispatcher delegate
		self.dispatcher = [[PureDataDispatcher alloc] init];
		[PdBase setDelegate:self.dispatcher pollingEnabled:NO];
		
		// add this class as a receiver
		[self.dispatcher addListener:self forSource:PD_OSC_S];
		[self.dispatcher addListener:self forSource:RJ_GLOBAL_S];
		[self.dispatcher addListener:self forSource:PARTY_GLOBAL_S];
		
		// setup externals
		[Externals setup];
		
		// open "external patches" that always run in the background
		[PdBase openFile:@"recorder.pd" path:[Util.bundlePath stringByAppendingPathComponent:@"patches/lib/pd"]];

		// set ticks per buffer after everything else is set up, setting a tpb
		// of 1 too early results in no audio and feedback until it is changed,
		// this fixes that
		self.ticksPerBuffer = (int)[defaults integerForKey:@"ticksPerBuffer"];

		// setup display link for faster message polling
		updateLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMessages:)];
		updateLink.preferredFramesPerSecond = 60;
		[updateLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

		// observe audio route changes
		routeChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
			NSDictionary *info = notification.userInfo;
			if(info && info[AVAudioSessionRouteChangeReasonKey]) {
				AVAudioSession *session = AVAudioSession.sharedInstance;
				unsigned int reason = [info[AVAudioSessionRouteChangeReasonKey] unsignedIntValue];
				switch(reason) {
					case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
						LogVerbose(@"PureData: new device available, now %d inputs %d outputs",
							(int)session.inputNumberOfChannels, (int)session.outputNumberOfChannels);
						[self configureAudioUnitWithSampleRate:self->audioController.sampleRate];
						break;
					case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
						LogVerbose(@"PureData: old device unavailable, now %d inputs %d outputs",
							(int)session.inputNumberOfChannels, (int)session.outputNumberOfChannels);
						[self configureAudioUnitWithSampleRate:self->audioController.sampleRate];
						break;
					case AVAudioSessionRouteChangeReasonOverride:
						LogVerbose(@"PureData: device overidden, now %d inputs %d outputs",
							(int)session.inputNumberOfChannels, (int)session.outputNumberOfChannels);
						[self configureAudioUnitWithSampleRate:self->audioController.sampleRate];
						break;
					default:
						return;
				}
				LogVerbose(@"PureData: input \"%@\" output \"%@\"",
					[session.currentRoute.inputs.firstObject portName],
					[session.currentRoute.outputs.firstObject portName]);
			}
		}];
	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:routeChangeObserver];
	playbackPatch = nil;
	audioController = nil;
	if(updateLink) {
		[updateLink invalidate];
	}
	updateLink = nil;
}

- (int)calculateBufferSize {
	return audioController.ticksPerBuffer * [PdBase getBlockSize];
}

- (int)calculateLatency {
	return round(((float)[self calculateBufferSize] / (float)audioController.sampleRate) * 2.0 * 1000);
}

- (void)setAutoLatency:(BOOL)autoLatency {
	if(_autoLatency == autoLatency) {
		return;
	}
	_autoLatency = autoLatency;
	[NSUserDefaults.standardUserDefaults setBool:autoLatency forKey:@"autoLatency"];
}

#pragma mark Current Play Values

- (void)sendCurrentPlayValues {
	[PureData sendTransportPlay:_playing]; // [soundoutput] gate
	[PureData sendVolume:_volume]; // [soundoutput] level
	[PureData sendMicVolume:_micVolume]; // [soundinput] level
}

- (void)startRecordingTo:(NSString *)path {
	if(self.isRecording) return;
	[PdBase sendMessage:@"scene" withArguments:@[path] toReceiver:RJ_TRANSPORT_R];
	[PdBase sendMessage:@"record" withArguments:@[@YES] toReceiver:RJ_TRANSPORT_R];
	self.recording = YES;
	LogVerbose(@"PureData: started recording to %@", path);
}

- (void)stopRecording {
	if(!self.isRecording) return;
	[PdBase sendMessage:@"record" withArguments:@[@NO] toReceiver:RJ_TRANSPORT_R];
	self.recording = NO;
	LogVerbose(@"PureData: stopped recording");
}

- (BOOL)startedRecordingToRecordDir:(NSString *)path withTimestamp:(BOOL)timestamp {
	if(self.isRecording) return NO;

	NSString *recordDir = [Util.documentsPath stringByAppendingPathComponent:RECORDINGS_DIR];
	if(![NSFileManager.defaultManager fileExistsAtPath:recordDir]) {
		LogVerbose(@"PureData: recordings dir not found, creating %@", recordDir);
		NSError *error;
		if(![NSFileManager.defaultManager createDirectoryAtPath:recordDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			LogError(@"PureData: couldn't create %@, error: %@", recordDir, error.localizedDescription);
			return NO;
		}
	}

	if(timestamp) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"MM-dd-yyyy_HH-mm-ss"];
		NSString *date = [formatter stringFromDate:[NSDate date]];
		NSString *filename = [NSString stringWithFormat:@"%@_%@.wav", date, path.stringByDeletingPathExtension];
		[self startRecordingTo:[recordDir stringByAppendingPathComponent:filename]];
	}
	else {
		[self startRecordingTo:[recordDir stringByAppendingPathComponent:
			[path.stringByDeletingPathExtension stringByAppendingFormat:@".wav"]]];
	}
	return YES;
}

#pragma mark Send Events


+ (void)sendTouch:(NSString *)eventType forIndex:(int)index atPosition:(CGPoint)position {
	[PdBase sendMessage:eventType
	      withArguments:@[@(index+1), @(position.x), @(position.y)]
	         toReceiver:RJ_TOUCH_R];
}

+ (void)sendExtendedTouch:(NSString *)eventType forIndex:(int)index
               atPosition:(CGPoint)position
               withRadius:(float)radius andForce:(float)force; {
	[PdBase sendMessage:eventType
	      withArguments:@[@(index+1), @(position.x), @(position.y), @(radius), @(force)]
	         toReceiver:RJ_TOUCH_R];
}

+ (void)sendStylus:(NSString *)eventType forIndex:(int)index
        atPosition:(CGPoint)position withArguments:(NSArray *)arguments {
	[PdBase sendMessage:eventType
	      withArguments:@[@(index+1), @(position.x), @(position.y),
	                      arguments[0], arguments[1], arguments[2], arguments[3]]
	         toReceiver:PARTY_STYLUS_R];
}

+ (void)sendAccel:(float)x y:(float)y z:(float)z {
	[PdBase sendList:@[@(x), @(y), @(z)] toReceiver:RJ_ACCELERATE_R];
}

+ (void)sendGyro:(float)x y:(float)y z:(float)z {
	[PdBase sendList:@[@(x), @(y), @(z)] toReceiver:RJ_GYRO_R];
}

+ (void)sendLocation:(float)lat lon:(float)lon accuracy:(float)accuracy {
	[PdBase sendList:@[@(lat), @(lon), @(accuracy)] toReceiver:RJ_LOCATION_R];
}

+ (void)sendSpeed:(float)speed course:(float)course {
	[PdBase sendList:@[@(speed), @(course)] toReceiver:PARTY_SPEED_R];
}

+ (void)sendAltitude:(float)altitude accuracy:(float)accuracy {
	[PdBase sendList:@[@(altitude), @(accuracy)] toReceiver:PARTY_ALTITUDE_R];
}

+ (void)sendCompass:(float)degrees {
	[PdBase sendList:@[@(degrees)] toReceiver:RJ_COMPASS_R];
}

+ (void)sendTime:(NSArray *)time {
	[PdBase sendList:time toReceiver:RJ_TIME_R];
}

+ (void)sendMagnet:(float)x y:(float)y z:(float)z {
	[PdBase sendList:@[@(x), @(y), @(z)] toReceiver:PARTY_MAGNET_R];
}

+ (void)sendMotionAttitude:(float)pitch roll:(float)roll yaw:(float)yaw {
	[PdBase sendMessage:@"attitude"
	      withArguments:@[@(pitch), @(roll), @(yaw)]
	         toReceiver:PARTY_MOTION_R];
}

+ (void)sendMotionRotation:(float)x y:(float)y z:(float)z {
	[PdBase sendMessage:@"rotation"
	      withArguments:@[@(x), @(y), @(z)]
	         toReceiver:PARTY_MOTION_R];
}

+ (void)sendMotionGravity:(float)x y:(float)y z:(float)z {
	[PdBase sendMessage:@"gravity"
	      withArguments:@[@(x), @(y), @(z)]
	         toReceiver:PARTY_MOTION_R];
}

+ (void)sendMotionUser:(float)x y:(float)y z:(float)z {
	[PdBase sendMessage:@"user"
	      withArguments:@[@(x), @(y), @(z)]
	         toReceiver:PARTY_MOTION_R];
}

+ (void)sendEvent:(NSString *)event forController:(NSString *)controller {
	[PdBase sendMessage:[NSString stringWithString:event]
	      withArguments:@[[NSString stringWithString:controller]]
	         toReceiver:PARTY_CONTROLLER_R];
}

+ (void)sendController:(NSString *)controller button:(NSString *)button state:(BOOL)state {
	[PdBase sendMessage:[NSString stringWithString:controller]
	      withArguments:@[@"button", [NSString stringWithString:button], [NSNumber numberWithFloat:state]]
	         toReceiver:PARTY_CONTROLLER_R];
}

+ (void)sendController:(NSString *)controller axis:(NSString *)axis value:(float)value {
	[PdBase sendMessage:[NSString stringWithString:controller]
	      withArguments:@[@"axis", [NSString stringWithString:axis], [NSNumber numberWithFloat:value]]
	         toReceiver:PARTY_CONTROLLER_R];
}

+ (void)sendControllerPause:(NSString *)controller {
	[PdBase sendMessage:[NSString stringWithString:controller]
	      withArguments:@[@"pause"]
	         toReceiver:PARTY_CONTROLLER_R];
}

+ (void)sendShake {
	[PdBase sendBangToReceiver:PARTY_SHAKE_R];
}

+ (void)sendKey:(int)key {
	[PdBase sendFloat:key toReceiver:PD_KEY_R];
}

+ (void)sendKeyUp:(int)key {
	[PdBase sendFloat:key toReceiver:PD_KEYUP_R];
}

+ (void)sendKeyName:(NSString *)name pressed:(BOOL)pressed {
	[PdBase sendList:@[@((int)pressed), name] toReceiver:PD_KEYNAME_R];
}

+ (void)sendPrint:(NSString *)print {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	LogInfo(@"Pd: %@", print);
	[app.osc sendPrint:print];
}

// mimic [oscparse] by separating address components,
// send as a message to avoid the "list" type prepend
+ (void)sendOscMessage:(NSString *)address withArguments:(NSArray *)arguments {
	NSMutableArray *list = [NSMutableArray array];
	NSString *firstComponent = NULL;
	NSArray *components = [address componentsSeparatedByString:@"/"];
	for(NSString *s in components) {
		if(![s isEqualToString:@""]) { // first component is empty
			if(!firstComponent) {
				firstComponent = s; // first non-empty component
			}
			else {
				[list addObject:s]; // everything else
			}
		}
	}
	[list addObjectsFromArray:arguments];
	if(!firstComponent) {
		LogWarn(@"PureData: dropping OSC message with empty address");
		return;
	}
	if([firstComponent isEqualToString:PARTY_OSC_R]) { // catch incoming control messages
		if(list.count > 0 && [list.firstObject isKindOfClass:NSString.class] ) {
			if([list.firstObject isEqualToString:RJ_GLOBAL_S]) { // forward rj messages
				[PdBase sendMessage:[list firstObject]
				      withArguments:[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, list.count-1)]]
				         toReceiver:list.firstObject];
			}
			else { // process pdparty messages
				AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
				[app.pureData receiveMessage:list.firstObject
				               withArguments:[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, list.count-1)]]
				                  fromSource:PARTY_GLOBAL_S];
			}
		}
	}
	else { // forward everything else
		[PdBase sendMessage:firstComponent withArguments:list toReceiver:PD_OSC_R];
	}
}

+ (void)sendCloseBang {
	[PdBase sendBangToReceiver:PD_CLOSEBANG_R];
}

#pragma mark Send Values

+ (void)sendTransportPlay:(BOOL)play {
	[PdBase sendMessage:@"play" withArguments:@[@(play)] toReceiver:RJ_TRANSPORT_R];
}

+ (void)sendVolume:(float)volume {
	[PdBase sendMessage:@"set" withArguments:@[@(volume)] toReceiver:RJ_VOLUME_R];
}

+ (void)sendMicVolume:(float)micVolume {
	[PdBase sendFloat:micVolume toReceiver:RJ_MICVOLUME_R];
}

#pragma mark PdReceiverDelegate

- (void)receiveBangFromSource:(NSString *)source {
	LogVerbose(@"PureData: dropped bang");
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	LogVerbose(@"PureData: dropped float: %f", received);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	LogVerbose(@"PureData: dropped symbol: %@", symbol);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if([source isEqualToString:PD_OSC_S]) {
		[self.osc sendPacket:[self encodeList:list]];
	}
	else if(([source isEqualToString:RJ_GLOBAL_S] || [source isEqualToString:PARTY_GLOBAL_S])) { // catch list prepends
		if(list.count > 0) {
			[self receiveMessage:list.firstObject
			       withArguments:[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, list.count-1)]]
			          fromSource:source];
		}
	}
	else {
		LogVerbose(@"PureData: dropped list: %@", list.description);
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	if([source isEqualToString:PD_OSC_S]) {
		[self.osc sendPacket:[self encodeList:[[NSArray arrayWithObject:message] arrayByAddingObjectsFromArray:arguments]]];
	}
	else if([source isEqualToString:PARTY_GLOBAL_S]) {
		static NSString *sceneName = nil; // received scene name
		static BOOL appendTimestamp = NO; // append timestamp to scene name?

		// touch control
		if([message isEqualToString:@"touch"] && arguments.count > 1) {
			if([arguments[0] isEqualToString:@"extended"] && [arguments isNumberAt:1]) {
				if(self.sensorDelegate && [self.sensorDelegate supportsExtendedTouch]) {
					self.sensors.extendedTouchEnabled = [arguments[1] boolValue];
				}
			}
			else if([arguments[0] isEqualToString:@"everywhere"] && [arguments isNumberAt:1]) {
				if(self.sensorDelegate) {
					[self.sensorDelegate touchEverywhere:[arguments[1] boolValue]];
				}
			}
		}

		// accel control
		else if([message isEqualToString:@"accelerate"] && arguments.count > 0) {
			if([arguments isNumberAt:0]) { // float: start/stop
				if(self.sensorDelegate && [self.sensorDelegate supportsAccel]) {
					self.sensors.accelEnabled = [arguments[0] boolValue];
				}
			}
			else if([arguments isStringAt:0] && arguments.count > 1) {
				if([arguments[0] isEqualToString:@"speed"] && [arguments isStringAt:1]) {
					self.sensors.accelSpeed = arguments[1];
				}
			}
			else if([arguments[0] isEqualToString:@"orientation"] && [arguments isNumberAt:1]) {
				self.sensors.accelOrientation = [arguments[1] boolValue];
			}
		}
		
		// gyro control
		else if([message isEqualToString:@"gyro"]) {
			if(arguments.count == 0) {
				[self.sensors sendGyro];
			}
			else {
				if([arguments isNumberAt:0]) { // float: start/stop
					if(self.sensorDelegate && [self.sensorDelegate supportsGyro]) {
						self.sensors.gyroEnabled = [arguments[0] boolValue];
					}
				}
				else if([arguments isStringAt:0] && arguments.count > 1) {
					if([arguments[0] isEqualToString:@"updates"] && [arguments isNumberAt:1]) {
						self.sensors.gyroAutoUpdates = [arguments[1] boolValue];
					}
					else if([arguments[0] isEqualToString:@"speed"] && [arguments isStringAt:1]) {
						self.sensors.gyroSpeed = arguments[1];
					}
				}
			}
		}
	
		// location service control
		else if([message isEqualToString:@"loc"]) {
			if(arguments.count == 0) {
				[self.sensors sendLocation];
			}
			else {
				if([arguments isNumberAt:0]) { // float: start/stop
					if(self.sensorDelegate && [self.sensorDelegate supportsLocation]) {
						self.sensors.locationEnabled = [arguments[0] boolValue];
					}
				}
				else if([arguments isStringAt:0] && arguments.count > 1) {
					if([arguments[0] isEqualToString:@"updates"] && [arguments isNumberAt:1]) {
						self.sensors.locationAutoUpdates = [arguments[1] boolValue];
					}
					else if([arguments[0] isEqualToString:@"accuracy"] && [arguments isStringAt:1]) {
						self.sensors.locationAccuracy = arguments[1];
					}
					else if([arguments[0] isEqualToString:@"filter"] && [arguments isNumberAt:1]) {
						self.sensors.locationFilter = [arguments[1] floatValue];
					}
				}
			}
		}
		
		// compass control
		else if([message isEqualToString:@"compass"]) {
			if(arguments.count == 0) {
				[self.sensors sendCompass];
			}
			else {
				if([arguments isNumberAt:0]) { // float: start/stop
					if(self.sensorDelegate && [self.sensorDelegate supportsCompass]) {
						self.sensors.compassEnabled = [arguments[0] boolValue];
					}
				}
				else if([arguments isStringAt:0] && arguments.count > 1) {
					if([arguments[0] isEqualToString:@"updates"] && [arguments isNumberAt:1]) {
						self.sensors.compassAutoUpdates = [arguments[1] boolValue];
					}
					else if([arguments[0] isEqualToString:@"filter"] && [arguments isNumberAt:1]) {
						self.sensors.compassFilter = [arguments[1] floatValue];
					}
				}
			}
		}
		
		// magnetometer control
		else if([message isEqualToString:@"magnet"]) {
			if(arguments.count == 0) {
				[self.sensors sendMagnet];
			}
			else {
				if([arguments isNumberAt:0]) { // float: start/stop
					if(self.sensorDelegate && [self.sensorDelegate supportsMagnet]) {
						self.sensors.magnetEnabled = [arguments[0] boolValue];
					}
				}
				else if([arguments isStringAt:0] && arguments.count > 1) {
					if([arguments[0] isEqualToString:@"updates"] && [arguments isNumberAt:1]) {
						self.sensors.magnetAutoUpdates = [arguments[1] boolValue];
					}
					else if([arguments[0] isEqualToString:@"speed"] && [arguments isStringAt:1]) {
						self.sensors.magnetSpeed = arguments[1];
					}
				}
			}
		}

		// motion control
		if([message isEqualToString:@"motion"]) {
			if(arguments.count == 0) {
				[self.sensors sendMotion];
			}
			else {
				if([arguments isNumberAt:0]) { // float: start/stop
					if(self.sensorDelegate && [self.sensorDelegate supportsMotion]) {
						self.sensors.motionEnabled = [arguments[0] boolValue];
					}
				}
				else if([arguments isStringAt:0] && arguments.count > 1) {
					if([arguments[0] isEqualToString:@"updates"] && [arguments isNumberAt:1]) {
						self.sensors.motionAutoUpdates = [arguments[1] boolValue];
					}
					else if([arguments[0] isEqualToString:@"speed"] && [arguments isStringAt:1]) {
						self.sensors.motionSpeed = arguments[1];
					}
				}
			}
		}
	
		// set the scene name for remote recording
		else if([message isEqualToString:@"scene"] && arguments.count > 0 && [arguments isStringAt:0]) {
			sceneName = arguments[0];
			if(arguments.count > 1 && [arguments isNumberAt:1]) {
				appendTimestamp = [arguments[1] boolValue];
			}
			else {
				appendTimestamp = NO;
			}
		}
	
		// start/stop recording remotely, set scene name first
		else if([message isEqualToString:@"record"] && arguments.count > 0 && [arguments isNumberAt:0]) {
			if([arguments[0] boolValue]) {
				if(sceneName && [self startedRecordingToRecordDir:sceneName.lastPathComponent withTimestamp:appendTimestamp]) {
					if(self.recordDelegate) {
						[self.recordDelegate remoteRecordingStarted];
					}
				}
			}
			else {
				if(!self.isRecording) {
					return;
				}
				[self stopRecording];
				if(self.recordDelegate) {
					[self.recordDelegate remoteRecordingFinished];
				}
			}
		}
		
		// open a url
		else if([message isEqualToString:@"openurl"] && arguments.count > 0 && [arguments isStringAt:0]) {
			NSURL *url = [NSURL URLWithString:arguments[0]];
			LogVerbose(@"PureData: openurl %@", url);
			// local file
			if(!url.scheme || [url.scheme isEqualToString:@""] ||
			   [url.scheme isEqualToString:@"file"]) {
				AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
				NSString *title = nil;
				if(arguments.count > 1) { // build title
					NSArray *array = [arguments objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, arguments.count-1)]];
					title = [array componentsJoinedByString:@" "];
				}
				[app launchWebViewForURL:url withTitle:title sceneRotationsOnly:YES];
			}
			else { // pass to openURL to open in Safari or some other app
				UIApplication *application = UIApplication.sharedApplication;
				[application openURL:url options:@{} completionHandler:^(BOOL success) {
					if(!success) {
						LogError(@"PureData: could not open url: %@", url);
					}
				}];
			}
		}
		
		// send a timestamp
		else if([message isEqualToString:@"time"]) {
			NSArray *time = [PureData timestamp];
			[PureData sendTime:time];
			[self.osc sendTime:time];
		}

		// dynamic background
		if([message isEqualToString:@"background"] && arguments.count > 0) {
			if([arguments[0] isEqualToString:@"load"] && arguments.count > 1 && [arguments isStringAt:1]) {
				if(self.backgroundDelegate) {
					[self.backgroundDelegate loadBackground:arguments[1]];
				}
			}
			else if([arguments[0] isEqualToString:@"clear"]) {
				if(self.backgroundDelegate) {
					[self.backgroundDelegate clearBackground];
				}
			}
		}
	}
	else {
		LogVerbose(@"PureData: dropped message: %@ %@", message, arguments.description);
	}
}

#pragma mark Overridden Getters / Setters

- (int)sampleRate {
	return audioController.sampleRate;
}

- (void)setSampleRate:(int)sampleRate {
	if(audioController.sampleRate == sampleRate) return;
	if(sampleRate <= 0) {
		LogWarn(@"PureData: ignoring obviously bad sample rate: %d", sampleRate);
		return;
	}
	[self configureAudioUnitWithSampleRate:sampleRate];
}

- (int)ticksPerBuffer {
	return audioController.ticksPerBuffer;
}

- (void)setTicksPerBuffer:(int)ticksPerBuffer {
	// always set value, don't check if ticksPerBuffer = _ticksPerBuffer since this
	// may lead to a buffer duration not being updated after a samplerate change
	
	if(ticksPerBuffer <= 0 || ticksPerBuffer > 32) {
		LogWarn(@"PureData: ignoring obviously bad ticks per buffer: %d", ticksPerBuffer);
		return;
	}

	PdAudioStatus status = [audioController configureTicksPerBuffer:ticksPerBuffer];
	if(status == PdAudioError) {
		LogError(@"PureData: could not set ticks per buffer");
	}
	else if(status == PdAudioPropertyChanged) {
		LogWarn(@"PureData: ticks per buffer value was not acceptable, using %d instead", audioController.ticksPerBuffer);
	}
	else {
		[NSUserDefaults.standardUserDefaults setInteger:ticksPerBuffer forKey:@"ticksPerBuffer"];
		LogVerbose(@"PureData: ticks per buffer now %d", audioController.ticksPerBuffer);
	}
}

- (BOOL)earpieceSpeaker {
	return (Util.isDeviceAPhone ? !audioController.defaultToSpeaker : NO);
}

- (void)setEarpieceSpeaker:(BOOL)earpieceSpeaker {
	if(!Util.isDeviceAPhone) return;
	audioController.defaultToSpeaker = !earpieceSpeaker;
	[NSUserDefaults.standardUserDefaults setBool:earpieceSpeaker forKey:@"earpieceSpeakerEnabled"];
}

- (int)userSampleRate {
	return (int)[NSUserDefaults.standardUserDefaults integerForKey:@"sampleRate"];
}

- (void)setUserSampleRate:(int)userSampleRate {
	[NSUserDefaults.standardUserDefaults setInteger:userSampleRate forKey:@"sampleRate"];
}

- (BOOL)isAudioEnabled {
	return audioController.active;
}

- (void)setAudioEnabled:(BOOL)enabled {
	if(audioController.active == enabled) return;
	audioController.active = enabled;
	updateLink.paused = !enabled;
}

- (void)setPlaying:(BOOL)playing {
	if(_playing == playing) return;
	_playing = playing;
	[PureData sendTransportPlay:_playing];
}

- (void)setVolume:(float)volume {
	_volume = CLAMP(volume, 0.0, 1.0);
	[PureData sendVolume:_volume];
}

- (void)setMicVolume:(float)micVolume {
	_micVolume = CLAMP(micVolume, 0.0, 1.0);
	[NSUserDefaults.standardUserDefaults setFloat:_micVolume forKey:@"micVolume"];
	[PureData sendMicVolume:_micVolume]; // [soundinput] control
}

- (void)setOsc:(Osc *)osc {
	_osc = osc;
	self.dispatcher.osc = osc;
}

#pragma mark Find

// following find functionality adapted from g_editor.c,
// some forward declares, etc
static int canvas_find_index, canvas_find_wholeword;
static t_binbuf *canvas_findbuf;

// this one checks that a pd is indeed a patchable object, and returns
// it, correctly typed, or zero if the check failed.
t_object *pd_checkobject(t_pd *x);

// function to support searching
static int atoms_match(int inargc, t_atom *inargv, int searchargc,
	t_atom *searchargv, int wholeword) {
	int indexin, nmatched;
	for(indexin = 0; indexin <= inargc - searchargc; indexin++) {
		for(nmatched = 0; nmatched < searchargc; nmatched++) {
			t_atom *a1 = &inargv[indexin + nmatched], 
				*a2 = &searchargv[nmatched];
			if(a1->a_type == A_SEMI || a1->a_type == A_COMMA) {
				if(a2->a_type != a1->a_type) {
					goto nomatch;
				}
			}
			else if(a1->a_type == A_FLOAT || a1->a_type == A_DOLLAR) {
				if(a2->a_type != a1->a_type ||
				   a1->a_w.w_float != a2->a_w.w_float) {
					goto nomatch;
				}
			}
			else if(a1->a_type == A_SYMBOL || a1->a_type == A_DOLLSYM) {
				if((a2->a_type != A_SYMBOL && a2->a_type != A_DOLLSYM) ||
				   (wholeword && a1->a_w.w_symbol != a2->a_w.w_symbol) ||
				   (!wholeword &&  !strstr(a1->a_w.w_symbol->s_name,
					                       a2->a_w.w_symbol->s_name))) {
					goto nomatch;
				}
			}
		}
		return 1;
	nomatch: ;
	}
	return 0;
}

// find an atom or string of atoms
static int canvas_dofind(t_canvas *x, int *myindexp) {
	t_gobj *y;
	int findargc = binbuf_getnatom(canvas_findbuf), didit = 0;
	t_atom *findargv = binbuf_getvec(canvas_findbuf);
	for(y = x->gl_list; y; y = y->g_next) {
		t_object *ob = 0;
		if((ob = pd_checkobject(&y->g_pd))) {
			if(atoms_match(binbuf_getnatom(ob->ob_binbuf),
				binbuf_getvec(ob->ob_binbuf), findargc, findargv,
					canvas_find_wholeword)) {
				if(*myindexp == canvas_find_index) {
					didit = 1;
				}
				(*myindexp)++;
			}
		}
	}
	for(y = x->gl_list; y; y = y->g_next) {
		if(pd_class(&y->g_pd) == canvas_class) {
			didit |= canvas_dofind((t_canvas *)y, myindexp);
		}
	}
	return didit;
}

// TODO: move this to PdParser when parsing
+ (BOOL)objectExists:(NSString *)name inPatch:(PdFile *)patch {
	t_canvas *canvas = (t_canvas *)[patch.fileReference pointerValue];
	t_symbol *n = gensym([name cStringUsingEncoding:NSUTF8StringEncoding]);
	int myindex = 0;
	if(!canvas_findbuf) {
		canvas_findbuf = binbuf_new();
	}
	binbuf_text(canvas_findbuf, n->s_name, strlen(n->s_name));
	canvas_find_index = 0;
	canvas_find_wholeword = 1;
	BOOL found = canvas_dofind(canvas, &myindex);
	binbuf_clear(canvas_findbuf);
	return found;
}

#pragma mark Util

static NSDateFormatter *s_timeFormatter = nil;
static NSNumberFormatter *s_numFormatter = nil;

// http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
+ (NSArray *)timestamp {
	if(!s_timeFormatter) {
		s_timeFormatter = [[NSDateFormatter alloc] init];
		s_timeFormatter.dateFormat = @"yyyy MM dd FF DD Z HH mm ss A";
		s_numFormatter = [[NSNumberFormatter alloc] init];
		s_numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	}
	NSMutableArray *time = [NSMutableArray arrayWithArray:[[s_timeFormatter stringFromDate:[NSDate date]] componentsSeparatedByString:@" "]];
	for(int i = 0; i < time.count; ++i) {
		if(i == 5 && [time[i] characterAtIndex:0] == '+') {
			// catch leading tz + which s_numFormatter can't handle
			time[i] = [time[i] stringByReplacingOccurrencesOfString:@"+" withString:@""];
		}
		NSNumber *n = [s_numFormatter numberFromString:time[i]];
		time[i] = n;
	}
	return time;
}

#pragma mark Private

// configure for playback w/ sample rate, number of channels, ticks per buffer
// try to open a min of 2 input 2 output
- (void)configureAudioUnitWithSampleRate:(int)sampleRate {

	// allow for multiple i/o by using the session's channel numbers
	AVAudioSession *session = AVAudioSession.sharedInstance;

	// nothing to change?
	if(audioController.sampleRate == sampleRate &&
	   audioController.inputChannels == (int)session.inputNumberOfChannels &&
	   audioController.outputChannels == (int)session.outputNumberOfChannels) {
		return;
	}

	audioController.active = NO;
	int inputs = (int)session.inputNumberOfChannels;
	int outputs = (int)session.outputNumberOfChannels;
	int tpb = audioController.ticksPerBuffer;
	PdAudioStatus status = [audioController configurePlaybackWithSampleRate:sampleRate
	                                                          inputChannels:inputs
	                                                         outputChannels:outputs
	                                                           inputEnabled:YES];
	if(status == PdAudioError) {
		LogError(@"PureData: could not configure audio");
	}
	else if(status == PdAudioPropertyChanged) {
		LogWarn(@"PureData: some of the audio properties were changed during configuration");
		[audioController print];
	}
	LogVerbose(@"PureData: sampleRate %d inputs %d outputs %d",
				 audioController.sampleRate, audioController.inputChannels, audioController.outputChannels);

	// (re)set tpb if we're not letting the latency be chosen automatically
	// by the audioController
	if(!self.autoLatency && audioController.ticksPerBuffer != tpb) {
		LogVerbose(@"PureData: resetting ticks per buffer");
		[self setTicksPerBuffer:tpb];
	}

	// catch zero ticks per buffer
	if(audioController.ticksPerBuffer <= 0) {
		[self setTicksPerBuffer:1];
		LogVerbose(@"PureData: caught 0 ticksPerBuffer, setting to 1");
	}

	audioController.active = YES;
}

// process messages waiting in the queues
- (void)updateMessages:(CADisplayLink *)displayLink {
	[PdBase receiveMessages];
	[PdBase receiveMidi];
}

// encode a libpd list of numbers into raw byte data
- (NSData *)encodeList:(NSArray *)list {
	NSMutableData *data = [NSMutableData data];
	for(NSObject *o in list) {
		if([o isKindOfClass:NSNumber.class]) {
			unsigned char byte[1];
			byte[0] = [(NSNumber *)o charValue];
			[data appendBytes:byte length:1];
		}
		else {
			LogWarn(@"PureData: cannot encode non-numeric list argument: %@", o);
			data = nil;
			break;
		}
	}
	return data;
}

@end

@implementation PureDataDispatcher

- (void)receivePrint:(NSString *)message {
	LogInfo(@"%@", message);
	[self.osc sendPrint:message];
}

@end
