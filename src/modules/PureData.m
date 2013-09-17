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

#import "Log.h"
#import "Midi.h"
#import "Osc.h"
#import "PdAudioController.h"
#import "Externals.h"
#import "Util.h"

@interface PureData () {
	PdAudioController *audioController;
	PdFile *playbackPatch;
}
@property (assign, readwrite, getter=isRecording, nonatomic) BOOL recording;
@property (assign, readwrite, getter=isPlayingback, nonatomic) BOOL playingback;
@end

@implementation PureData

@synthesize audioEnabled;

- (id)init {
	self = [super init];
	if(self) {

		_micVolume = [[NSUserDefaults standardUserDefaults] floatForKey:@"micVolume"];
		_volume = 1.0;
		_playing = YES;
		_recording = NO;
		_playingback = NO;
		_looping = NO;

		// configure a typical audio session with 2 output channels
		audioController = [[PdAudioController alloc] init];
		self.sampleRate = PARTY_SAMPLERATE;
		self.ticksPerBuffer = [[NSUserDefaults standardUserDefaults] integerForKey:@"ticksPerBuffer"];
		if(ddLogLevel >= LOG_LEVEL_VERBOSE) {
			[audioController print];
		}
		
		// set dispatcher delegate
		self.dispatcher = [[PureDataDispatcher alloc] init];
		[PdBase setDelegate:self.dispatcher];
		
		// set midi receiver delegate
		[PdBase setMidiDelegate:self];
		
		// add this class as a receiver
		[self.dispatcher addListener:self forSource:PD_OSC_S];
		[self.dispatcher addListener:self forSource:RJ_GLOBAL_S];
		
		// setup externals
		[Externals setup];
		
		// open "external patches" that always run in the background
		[PdBase openFile:@"recorder.pd" path:[[Util bundlePath] stringByAppendingPathComponent:@"patches/lib/rj"]];
	}
	return self;
}

- (int)calculateBufferSize {
	return audioController.ticksPerBuffer * [PdBase getBlockSize];
}

- (float)calculateLatency {
	return ((float)[self calculateBufferSize] / (float)audioController.sampleRate) * 2.0 * 1000;
}

#pragma mark Current Play Values

- (void)sendCurrentPlayValues {
	[PureData sendTransportPlay:_playing];
	[PureData sendTransportLoop:_looping];
	[PureData sendMicVolume:_micVolume];
	[PureData sendVolume:_volume];
}

- (void)startRecordingTo:(NSString *)path {
	if(self.isRecording) return;
	[PdBase sendMessage:@"scene" withArguments:[NSArray arrayWithObject:path] toReceiver:RJ_TRANSPORT_R];
	[PdBase sendMessage:@"record" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:YES]] toReceiver:RJ_TRANSPORT_R];
	self.recording = YES;
	DDLogVerbose(@"PureData: started recording to %@", path);
}

- (void)stopRecording {
	if(!self.isRecording) return;
	[PdBase sendMessage:@"record" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:NO]] toReceiver:RJ_TRANSPORT_R];
	self.recording = NO;
	DDLogVerbose(@"PureData: stopped recording");
}

- (void)startPlaybackFrom:(NSString *)path {
	if(!playbackPatch) {
		playbackPatch = [PdFile openFileNamed:@"playback.pd" path:[[Util bundlePath] stringByAppendingPathComponent:@"patches/lib/rj"]];
	}
	[PdBase sendMessage:@"playback" withArguments:[NSArray arrayWithObject:path] toReceiver:RJ_TRANSPORT_R];
	self.playingback = YES;
	DDLogVerbose(@"PureData: started playing back from %@", path);
}

- (void)stopPlayback {
	if(playbackPatch) {
		[playbackPatch closeFile];
		playbackPatch = nil;
		DDLogVerbose(@"PureData: closed playback.pd");
	}
	self.playingback = NO;
}

#pragma mark Send Events

+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y {
	[PdBase sendMessage:eventType withArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:id+1], [NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], nil] toReceiver:RJ_TOUCH_R];
}

+ (void)sendAccel:(float)x y:(float)y z:(float)z {
	[PdBase sendList:[NSArray arrayWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], [NSNumber numberWithFloat:z], nil] toReceiver:RJ_ACCELERATE_R];
}

+ (void)sendKey:(int)key {
	[PdBase sendFloat:key toReceiver:PD_KEY_R];
}

+ (void)sendOscMessage:(NSString *)address withArguments:(NSArray *)arguments {
	[PdBase sendMessage:address withArguments:arguments toReceiver:PD_OSC_R];
}

#pragma mark Send Values

+ (void)sendTransportPlay:(BOOL)play {
	[PdBase sendMessage:@"play" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:play]] toReceiver:RJ_TRANSPORT_R];
}

+ (void)sendTransportLoop:(BOOL)loop {
	[PdBase sendMessage:@"loop" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:loop]] toReceiver:RJ_TRANSPORT_R];
}

+ (void)sendMicVolume:(float)micVolume {
	[PdBase sendFloat:micVolume toReceiver:RJ_MICVOLUME_R];
}

+ (void)sendVolume:(float)volume {
	[PdBase sendMessage:@"set" withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:volume]] toReceiver:RJ_VOLUME_R];
}

#pragma mark PdReceiverDelegate

- (void)receiveBangFromSource:(NSString *)source {
	DDLogWarn(@"PureData: dropped bang");
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogWarn(@"PureData: dropped float: %f", received);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogWarn(@"PureData: dropped symbol: %@", symbol);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	DDLogWarn(@"PureData: dropped list: %@", [list description]);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	
	if([source isEqualToString:RJ_GLOBAL_S]) {
	
		if([message isEqualToString:@"playback"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
			if([[arguments objectAtIndex:0] floatValue] < 1) {
				_playingback = NO;
				if(self.delegate) {
					[self.delegate playbackFinished];
				}
				DDLogVerbose(@"PureData: stopped playing back");
			}
		}
	}
	else if([source isEqualToString:PD_OSC_S]) {
		// message should be the osc address
		[self.osc sendMessage:message withArguments:arguments];
	}
}

#pragma mark PdMidiReceiverDelegate

- (void)receiveNoteOn:(int)pitch withVelocity:(int)velocity forChannel:(int)channel {
	[self.midi sendNoteOn:channel pitch:pitch velocity:velocity];
}

- (void)receiveControlChange:(int)value forController:(int)controller forChannel:(int)channel {
	[self.midi sendControlChange:channel controller:controller value:value];
}

- (void)receiveProgramChange:(int)value forChannel:(int)channel {
	[self.midi sendProgramChange:channel value:value];
}

- (void)receivePitchBend:(int)value forChannel:(int)channel {
	[self.midi sendPitchBend:channel value:value];
}

- (void)receiveAftertouch:(int)value forChannel:(int)channel {
	[self.midi sendAftertouch:channel value:value];
}

- (void)receivePolyAftertouch:(int)value forPitch:(int)pitch forChannel:(int)channel {
	[self.midi sendPolyAftertouch:channel pitch:pitch value:value];
}

- (void)receiveMidiByte:(int)byte forPort:(int)port {}

#pragma mark Overridden Getters / Setters

- (int)sampleRate {
	return audioController.sampleRate;
}

- (void)setSampleRate:(int)sampleRate {
	if(audioController.sampleRate == sampleRate) return;
	
	if(sampleRate <= 0) {
		DDLogWarn(@"PureData: ignoring obviously bad sampleRate: %d", sampleRate);
		return;
	}

	audioController.active = NO;
	PdAudioStatus status = [audioController configurePlaybackWithSampleRate:sampleRate
															 numberChannels:2
															   inputEnabled:YES
															  mixingEnabled:YES];
	if(status == PdAudioError) {
		DDLogError(@"PureData: could not configure PdAudioController");
	}
	else if(status == PdAudioPropertyChanged) {
		DDLogWarn(@"PureData: some of the audio parameters were not accceptable");
	}
	else {
		DDLogVerbose(@"PureData: sampleRate now %d", audioController.sampleRate);
	}
	
	[audioController configureTicksPerBuffer:2];
	DDLogVerbose(@"PureData: ticks per buffer: %d", audioController.ticksPerBuffer);
	audioController.active = YES;
}

- (int)ticksPerBuffer {
	return audioController.ticksPerBuffer;
}

- (void)setTicksPerBuffer:(int)ticksPerBuffer {
	if(audioController.ticksPerBuffer == ticksPerBuffer) return;
	
	if(ticksPerBuffer <= 0 || ticksPerBuffer > 32) {
		DDLogWarn(@"PureData: ignoring obviously bad ticks per buffer: %d", ticksPerBuffer);
		return;
	}

	PdAudioStatus status = [audioController configureTicksPerBuffer:ticksPerBuffer];
	if(status == PdAudioError) {
		DDLogError(@"PureData: could not set ticks per buffer");
	}
	else if(status == PdAudioPropertyChanged) {
		DDLogWarn(@"PureData: the ticks per buffer value was not accceptable");
	}
	else {
		[[NSUserDefaults standardUserDefaults] setInteger:ticksPerBuffer forKey:@"ticksPerBuffer"];
		DDLogVerbose(@"PureData: ticks per buffer now %d", audioController.ticksPerBuffer);
	}
}

- (BOOL)isAudioEnabled {
	return audioController.active;
}

- (void)setAudioEnabled:(BOOL)enabled {
    if(audioController.active == enabled) return;
	audioController.active = enabled;
}

- (void)setPlaying:(BOOL)playing {
	if(_playing == playing) return;
	_playing = playing;
	[PureData sendTransportPlay:_playing];
}

- (void)setLooping:(BOOL)looping {
	if(_looping == looping) return;
	_looping = looping;
	[PureData sendTransportLoop:_looping];
}

- (void)setVolume:(float)volume {
	_volume = MIN(MAX(volume, 0.0), 1.0); // clamp to 0-1
	[PureData sendVolume:_volume];
}

- (void)setMicVolume:(float)micVolume {
	_micVolume = MIN(MAX(micVolume, 0.0), 1.0); // clamp to 0-1
	[PureData sendMicVolume:_micVolume];
	[[NSUserDefaults standardUserDefaults] setFloat:_micVolume forKey:@"micVolume"];
}

- (void)setOsc:(Osc *)osc {
	_osc = osc;
	self.dispatcher.osc = osc;
}

@end

@implementation PureDataDispatcher

- (void)receivePrint:(NSString *)message {
	DDLogInfo(@"Pd: %@", message);
	[self.osc sendPrint:message];
}

@end
