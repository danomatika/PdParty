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

@interface PureData ()
@property (nonatomic, retain) PdAudioController *audioController;
@end

@implementation PureData

@synthesize audioEnabled;

- (id)init {
	self = [super init];
	if(self) {
		// configure a typical audio session with 2 output channels
		self.audioController = [[PdAudioController alloc] init];
		PdAudioStatus status = [self.audioController configurePlaybackWithSampleRate:44100
																	  numberChannels:2
																		inputEnabled:NO
																	   mixingEnabled:YES];
		if(status == PdAudioError) {
			DDLogError(@"Error: Could not configure PdAudioController");
		}
		else if(status == PdAudioPropertyChanged) {
			DDLogWarn(@"Warning: Some of the audio parameters were not accceptable");
		}
		else {
			DDLogInfo(@"Audio Configuration successful");
		}
		if(ddLogLevel >= LOG_LEVEL_VERBOSE) {
			[self.audioController print];
		}
		
		// set dispatcher delegate
		self.dispatcher = [[PdDispatcher alloc] init];
		[PdBase setDelegate:self.dispatcher];
		
		// set midi receiver delegate
		[PdBase setMidiDelegate:self];
	}
	return self;
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

#pragma mark Overridden Getters/Setters

- (BOOL)isAudioEnabled {
	return audioEnabled;
}

- (void)setAudioEnabled:(BOOL)enabled {
    if(self.audioEnabled == enabled) {
		return;
	}
	audioEnabled = enabled;
	self.audioController.active = self.audioEnabled;
}

@end
