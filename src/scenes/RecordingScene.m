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
#import "RecordingScene.h"

#import "ControlsView.h"
#import <AvFoundation/AVAudioPlayer.h>
#import "PureData.h"

@implementation RecordingScene

+ (id)sceneWithParent:(UIView *)parent andPureData:(PureData *)pureData {
	RecordingScene *s = [[RecordingScene alloc] init];
	s.parentView = parent;
	s.pureData = pureData;
	return s;
}

- (BOOL)open:(NSString *)path {
	
	self.file = path;
	[self.pureData startPlaybackFrom:self.file];
	
	// allow all orientations on iPad
	if([Util isDeviceATablet]) {
		self.preferredOrientations = UIInterfaceOrientationMaskAll;
	}
	else { // lock to portrait on iPhone
		self.preferredOrientations = UIInterfaceOrientationMaskPortrait;
	}
	
	// set samplerate based on file samplerate
	NSError *error;
	AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.file] error:&error];
	if(!player) {
		DDLogError(@"RecordingScene: couldn't check sample rate of %@: %@", [self.file lastPathComponent], error.localizedDescription);
	}
	else {
		self.pureData.sampleRate = [[player.settings objectForKey:AVSampleRateKey] integerValue];
		player = nil;
	}
	
	// load background
	NSString *backgroundPath = [[Util bundlePath] stringByAppendingPathComponent:@"images/cassette_tape.jpg"];
	if([[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
		self.background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
		if(!self.background.image) {
			DDLogError(@"RecordingScene: couldn't load background image");
		}
		self.background.contentMode = UIViewContentModeScaleAspectFill;
		[self.parentView addSubview:self.background];
	}
	else {
		DDLogWarn(@"RecordingScene: no background image");
	}
	
	return YES;
}

- (void)close {
	[self.pureData stopPlayback];
	self.file = nil;
	
	if(self.background) {
		[self.background removeFromSuperview];
		self.background = nil;
	}
	
	[super close];
}

- (void)reshape {
	CGSize viewSize, backgroundSize, controlsSize;
	CGFloat xPos = 0;
	
	// background is always square
	viewSize = self.parentView.frame.size;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
		backgroundSize.width = viewSize.width;
		backgroundSize.height = backgroundSize.width;
	}
	else {
		backgroundSize.width = viewSize.height * 0.8;
		backgroundSize.height = backgroundSize.width;
		xPos = (viewSize.width - backgroundSize.width)/2;
	}
	
	// set background
	if(self.background) {
		self.background.frame = CGRectMake(xPos, 0, backgroundSize.width, backgroundSize.height);
	}
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

- (void)restartPlayback {
	if(self.file) {
		[self.pureData startPlaybackFrom:self.file];
	}
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return [self.file lastPathComponent];
}

- (SceneType)type {
	return SceneTypeRecording;
}

- (NSString *)typeString {
	return @"RecordingScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = [UIColor blackColor];
			
			// add background to new parent view
			if(self.background) {
				[self.parentView addSubview:self.background];
			}
		}
	}
}

- (BOOL)requiresAccel {
	return NO;
}

- (BOOL)requiresTouch {
	return NO;
}

- (BOOL)requiresLocate {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

- (BOOL)requiresOnscreenControls {
	return YES;
}

- (int)contentHeight {
	return CGRectGetHeight(self.background.bounds);
}

#pragma mark Util

+ (BOOL)isRecording:(NSString *)fullpath; {
	return [[fullpath pathExtension] isEqualToString:@"wav"];
}

@end
