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
#import <AVKit/AVPlayerViewController.h>
#import "PureData.h"

@implementation RecordingScene

+ (id)sceneWithParent:(UIView *)parent {
	RecordingScene *s = [[RecordingScene alloc] init];
	s.parentView = parent;
	return s;
}

- (BOOL)open:(NSString *)path {
	self.file = path;

	// load player
	AVPlayer *sound = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
	if(!sound) {
		DDLogWarn(@"RecordingScene: couldn't create player for: %@", [self.file lastPathComponent]);
		return NO;
	}
	self.player = [[AVPlayerViewController alloc] init];
	self.player.player = sound;
	self.player.showsPlaybackControls = YES;
	self.player.allowsPictureInPicturePlayback = NO;
	self.player.view.bounds = self.parentView.bounds;
	[self.parentView addSubview:self.player.view];

	// allow all orientations on iPad
	if([Util isDeviceATablet]) {
		self.preferredOrientations = UIInterfaceOrientationMaskAll;
	}
	else { // lock to portrait on iPhone
		self.preferredOrientations = UIInterfaceOrientationMaskPortrait;
	}

	// load background
	NSString *backgroundPath = [[Util bundlePath] stringByAppendingPathComponent:@"images/cassette_tape.jpg"];
	if([[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
		self.background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
		if(!self.background.image) {
			DDLogError(@"RecordingScene: couldn't load background image");
		}
		self.background.contentMode = UIViewContentModeScaleAspectFill;
		[self.player.contentOverlayView addSubview:self.background];
	}
	else {
		DDLogWarn(@"RecordingScene: no background image");
	}

	// load info label
	self.infoLabel = [UILabel new];
	self.infoLabel.text = [self.file lastPathComponent];
	self.infoLabel.font = [UIFont boldSystemFontOfSize:([Util isDeviceATablet] ? 22 : 17)];
	self.infoLabel.textColor = [UIColor whiteColor];
	self.infoLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.parentView.bounds);
	[self.infoLabel sizeToFit];
	[self.player.contentOverlayView addSubview:self.infoLabel];

	return YES;
}

- (void)close {
	self.file = nil;
	if(self.player) {
		[self.player.player pause];
		[self.player.view removeFromSuperview];
		self.player = nil;
	}
	self.background = nil;
	self.infoLabel = nil;

	[super close];
}

- (void)reshape {
	CGSize viewSize = self.parentView.bounds.size, backgroundSize;
	CGPoint offset = CGPointZero;

	// fill parent
	if(self.player) {
		self.player.view.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
	}

	// center background, always square
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
		backgroundSize.width = viewSize.width;
		backgroundSize.height = backgroundSize.width;
		offset.y = (viewSize.height - backgroundSize.height)/2;
	}
	else {
		backgroundSize.width = viewSize.height * 0.8;
		backgroundSize.height = backgroundSize.width;
		offset.x = (viewSize.width - backgroundSize.width)/2;
		offset.y = (viewSize.height - backgroundSize.height)/2;
	}
	if(self.background) {
		self.background.frame = CGRectMake(offset.x, offset.y, backgroundSize.width, backgroundSize.height);
	}

	// place info above background image
	self.infoLabel.preferredMaxLayoutWidth = viewSize.width;
	self.infoLabel.center = CGPointMake(viewSize.width/2,
	                                    offset.y - CGRectGetHeight(self.infoLabel.bounds)/2 - 22);
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

- (void)restartPlayback {
	if(self.player) {
		[self.player.player seekToTime:CMTimeMake(0, 1)];
	}
}

#pragma mark Overridden Getters / Setters

// hide nav bar title as filename is displayed in info label
- (NSString *)name {
	return @"";
}

- (NSString *)type {
	return @"RecordingScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = [UIColor blackColor];
			// add player to new parent view
			if(self.player) {
				[self.parentView addSubview:self.player.view];
			}
		}
	}
}

- (BOOL)requiresPd {
	return NO;
}

- (BOOL)requiresControls {
	return NO;
}

- (int)contentHeight {
	return CGRectGetHeight(self.parentView.bounds);
}

#pragma mark Util

+ (BOOL)isRecording:(NSString *)fullpath; {
	return [[fullpath pathExtension] isEqualToString:@"wav"];
}

@end
