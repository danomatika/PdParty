/*
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PartyAudioController.h"

#import "AudioHelpers.h"
#import "Util.h"

@interface PartyAudioController () {
	BOOL hasEarpiece;    //< does this device have an earpiece?
	BOOL optionsChanged; //< have the audio session options changed?
}
@end

@implementation PartyAudioController

@synthesize earpieceSpeaker = _earpieceSpeaker;

- (id)init {
	self = [super init];
	if(self) {
		hasEarpiece = [Util isDeviceAPhone];
		optionsChanged = NO;
	}
	return self;
}

- (AVAudioSessionCategoryOptions)playAndRecordOptions {
	AVAudioSessionCategoryOptions options =
		AVAudioSessionCategoryOptionMixWithOthers |
		AVAudioSessionCategoryOptionAllowBluetooth |
		AVAudioSessionCategoryOptionAllowAirPlay;
	if(!self.earpieceSpeaker) {
		options = AVAudioSessionCategoryOptionDefaultToSpeaker | options;
	}
	return options;
}

#pragma mark Overridden Getters/Setters

// make sure option changes are applied on restart
- (void)setActive:(BOOL)active {
	[super setActive:active];
	if(optionsChanged) {
		[self updateAudioSessionOptions];
	}
}

- (BOOL)earpieceSpeaker {
	return (hasEarpiece ? _earpieceSpeaker : NO);
}

- (void)setEarpieceSpeaker:(BOOL)earpieceSpeaker {
	if(!hasEarpiece) return;
	_earpieceSpeaker = earpieceSpeaker;
	[self updateAudioSessionOptions];
}

#pragma mark Private

- (void)updateAudioSessionOptions {
	if(!self.isActive) {
		// can't change now
		optionsChanged = YES;
		return;
	}
	[PdAudioController setSessionOptions:[self playAndRecordOptions]];
	optionsChanged = NO;
}

@end
