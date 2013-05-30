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
#import "PdAudioController.h"
#import "Externals.h"

@interface PureData () {
	PdAudioController *audioController;
}
@end

@implementation PureData

@synthesize audioEnabled;

- (id)init {
	self = [super init];
	if(self) {

		// configure a typical audio session with 2 output channels
		audioController = [[PdAudioController alloc] init];
		self.sampleRate = PARTY_SAMPLERATE;
		if(ddLogLevel >= LOG_LEVEL_VERBOSE) {
			[audioController print];
		}
		
		// set dispatcher delegate
		self.dispatcher = [[PdDispatcher alloc] init];
		[PdBase setDelegate:self.dispatcher];
		
		// set midi receiver delegate
		[PdBase setMidiDelegate:self];
		
		// setup externals
		[Externals setup];
	}
	return self;
}

#pragma mark Send Events

+ (void)sendKey:(int)key {
	[PdBase sendFloat:key toReceiver:PD_KEY_R];
}

+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y {
	[PdBase sendMessage:eventType withArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:id+1], [NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], nil] toReceiver:RJ_TOUCH_R];
}

+ (void)sendAccel:(float)x y:(float)y z:(float)z {
	[PdBase sendList:[NSArray arrayWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], [NSNumber numberWithFloat:z], nil] toReceiver:RJ_ACCELERATE_R];
}

+ (void)sendRotate:(float)degrees newOrientation:(NSString*)orientation {
	[PdBase sendList:[NSArray arrayWithObjects:[NSNumber numberWithFloat:degrees], orientation, nil] toReceiver:PARTY_ROTATE_R];
}

+ (void)sendPlay:(BOOL)playing {
	if(playing) {
		[PdBase sendMessage:@"play" withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:1]] toReceiver:RJ_TRANSPORT_R];
	}
	else {
		[PdBase sendMessage:@"play" withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:0]] toReceiver:RJ_TRANSPORT_R];
	}
}

// rj style input/output voluem controls
+ (void)sendVolume:(float)vol {
	[PdBase sendMessage:@"set" withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:vol]] toReceiver:RJ_VOLUME_R];
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
	if(audioController.sampleRate == sampleRate)	return;

	audioController.active = NO;
	PdAudioStatus status = [audioController configurePlaybackWithSampleRate:sampleRate
															 numberChannels:2
															   inputEnabled:YES
															  mixingEnabled:YES];
	if(status == PdAudioError) {
		DDLogError(@"PureData: Error: Could not configure PdAudioController");
	}
	else if(status == PdAudioPropertyChanged) {
		DDLogWarn(@"PureData: Warning: Some of the audio parameters were not accceptable");
	}
	else {
		DDLogInfo(@"PureData: sampleRate now %d", audioController.sampleRate);
	}
	audioController.active = YES;
}

- (BOOL)isAudioEnabled {
	return audioEnabled;
}

- (void)setAudioEnabled:(BOOL)enabled {
    if(self.audioEnabled == enabled) {
		return;
	}
	[PureData sendPlay:enabled];
	audioEnabled = enabled;
	audioController.active = self.audioEnabled;
}

@end
