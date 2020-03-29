/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * References:
 *   - http://binarymosaic.com/custom-video-player-for-ios-with-avfoundation
 *
 */
#import "RecordingScene.h"

#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>

@interface RecordingScene () {
	id timeObserver;      //< opaque player time update handle
	id endTimeObserver;   //< opaque player end time notification handle
	float rateBeforeSeek; //< stored player rate when seeking
}
@property (nonatomic) BOOL loop;    //< loop playback?
@property (nonatomic) BOOL seeking; //< is the time slider seeking?
@end

@implementation RecordingScene

+ (id)sceneWithParent:(UIView *)parent {
	RecordingScene *s = [[RecordingScene alloc] init];
	s.parentView = parent;
	return s;
}

- (BOOL)open:(NSString *)path {
	self.file = path;

	// load player
	self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
	if(self.player.error) {
		DDLogWarn(@"RecordingScene: couldn't create player for %@: %@",
			self.file.lastPathComponent, self.player.error);
		self.player = nil;
		return NO;
	}

	// allow all orientations on iPad
	if(Util.isDeviceATablet) {
		self.preferredOrientations = UIInterfaceOrientationMaskAll;
	}
	else { // lock to portrait on iPhone
		self.preferredOrientations = UIInterfaceOrientationMaskPortrait;
	}

	// load info label
	if(!Util.isDeviceATablet) {
		self.infoLabel = [[UILabel alloc] init];
		self.infoLabel.text = self.file.lastPathComponent;
		self.infoLabel.font = [UIFont boldSystemFontOfSize:17];
		self.infoLabel.textColor = UIColor.whiteColor;
		self.infoLabel.textAlignment = NSTextAlignmentCenter;
		self.infoLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.infoLabel.adjustsFontSizeToFitWidth = YES;
		self.infoLabel.numberOfLines = 1;
		[self.parentView addSubview:self.infoLabel];
	}

	// load background
	NSString *backgroundPath = [Util.bundlePath stringByAppendingPathComponent:@"images/tape_drive-512.png"];
	if([NSFileManager.defaultManager fileExistsAtPath:backgroundPath]) {
		UIImage *image = [UIImage imageWithContentsOfFile:backgroundPath];
		if(image) {
			image = [Util image:image withTint:UIColor.lightGrayColor];
			self.background = [[UIImageView alloc] initWithImage:image];
			self.background.contentMode = UIViewContentModeScaleAspectFill;
			[self.parentView addSubview:self.background];
		}
		else {
			DDLogError(@"RecordingScene: couldn't load background image");
		}
	}
	else {
		DDLogWarn(@"RecordingScene: no background image");
	}

	// load controls
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.parentView.frame), ControlsView.baseHeight);
	self.controlsView = [[PlayerControlsView alloc] initWithFrame:frame];
	self.controlsView.delegate = self;
	if(Util.isDeviceATablet) { // larger sizing for iPad
		[self.controlsView defaultSize];
	}
	[self.controlsView rightButtonToLoop];
	[self.parentView addSubview:self.controlsView];

	// update controls view on playback events
	__weak RecordingScene *wimp = self;
	timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                             queue:nil // main queue
	                                                    usingBlock:^(CMTime elapsed) {
		// update control labels and slider when playing
		if(!wimp.seeking) {
			[wimp.controlsView setElapsedTime:elapsed
							      forDuration:wimp.player.currentItem.duration];
			[wimp.controlsView setCurrentTime:elapsed forDuration:wimp.player.currentItem.duration];
		}
	}];
	endTimeObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
													  object:self.player.currentItem
	                                                   queue:nil // main queue
												  usingBlock:^(NSNotification *notification) {
		if(wimp.loop) { // restart playback at end
			[wimp.player seekToTime:CMTimeMake(0, 1)];
			[wimp.player play];
		}
		else { // stop
			[wimp.player seekToTime:CMTimeMake(0, 1)];
			[wimp.controlsView leftButtonToPlay];
		}
	}];
	[self.player.currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];

	return YES;
}

- (void)close {
	self.file = nil;
	if(self.player) {
		[self.player pause];
		[self.player removeTimeObserver:timeObserver];
		[self.player.currentItem removeObserver:self forKeyPath:@"status"];
		self.player = nil;
	}
	if(endTimeObserver) {
		[NSNotificationCenter.defaultCenter removeObserver:endTimeObserver];
	}
	[self.infoLabel removeFromSuperview];
	[self.background removeFromSuperview];
	[self.controlsView removeFromSuperview];
	self.infoLabel = nil;
	self.background = nil;
	self.controlsView = nil;
	[super close];
}

- (void)reshape {
	CGSize viewSize = self.parentView.bounds.size;
	CGSize backgroundSize;
	CGPoint offset = CGPointZero;

	// info on top, pad top with 1 line height
	if(self.infoLabel) {
		int lineHeight = [@"0" sizeWithAttributes:@{NSFontAttributeName : self.infoLabel.font}].height;
		self.infoLabel.preferredMaxLayoutWidth = viewSize.width*0.9;
		[self.infoLabel sizeToFit];
		if(CGRectGetWidth(self.infoLabel.frame) > self.infoLabel.preferredMaxLayoutWidth) {
			// catch overly long lines and shrink the width, not sure why this isn't
			// handled by preferredMaxLayoutWidth when using sizeToFit...
			CGRect frame = self.infoLabel.frame;
			frame.size.width = self.infoLabel.preferredMaxLayoutWidth;
			self.infoLabel.frame = frame;
		}
		self.infoLabel.center = CGPointMake(viewSize.width/2,
											CGRectGetHeight(self.infoLabel.frame)/2 + lineHeight);
		offset.y = CGRectGetHeight(self.infoLabel.frame) + lineHeight;
	}

	// square background space to match rjdj scene,
	// centered 1/2 size background image
	UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
	if(orientation == UIInterfaceOrientationPortrait ||
	   orientation == UIInterfaceOrientationPortraitUpsideDown) {
		backgroundSize.width = roundf(viewSize.width * 0.8);
		backgroundSize.height = backgroundSize.width;
		offset.x = roundf((viewSize.width - backgroundSize.width) / 2);
	}
	else {
		backgroundSize.width = roundf(viewSize.height * 0.8);
		backgroundSize.height = backgroundSize.width;
		offset.x = roundf((viewSize.width - backgroundSize.width) / 2);
	}
	if(self.background) {
		self.background.frame = CGRectMake(offset.x + backgroundSize.width * 0.25,
		                                   offset.y + backgroundSize.height * 0.25,
										   backgroundSize.width * 0.5,
		                                   backgroundSize.height * 0.5);
	}

	// place controls below background space
	self.controlsView.height = viewSize.height - backgroundSize.height - offset.y;
	[self.controlsView alignToSuperviewBottom];
	[self.parentView setNeedsUpdateConstraints];
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

#pragma mark KVO

// observe player item ready event
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if([object isKindOfClass:AVPlayerItem.class]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if([keyPath isEqualToString:@"status"]) {
            switch(item.status) {
                case AVPlayerItemStatusReadyToPlay:
 					// set time labels when loaded
					if(CMTimeCompare(self.player.currentTime, kCMTimeZero) == 0) {
						[self.controlsView resetForDuration:self.player.currentItem.duration];
					}
                	break;
                case AVPlayerItemStatusFailed:
                case AVPlayerItemStatusUnknown:
                default:
                	break;
            }
        }
    }
}

#pragma mark ControlsViewDelegate

// play/pause
- (void)controlsViewLeftPressed:(ControlsView *)controlsView {
	if(!self.player) {return;}
	if(self.player.rate > 0) {
		[self.player pause];
		[self.controlsView leftButtonToPlay];
	}
	else {
		[self.player play];
		[self.controlsView leftButtonToPause];
	}
}

// looping
- (void)controlsViewRightPressed:(ControlsView *)controlsView {
	if(!self.player) {return;}
	self.loop = !self.loop;
	if(self.loop) {
		[self.controlsView rightButtonToStopLoop];
	}
	else {
		[self.controlsView rightButtonToLoop];
	}
}

// start seeking, pause playback
- (void)controlsView:(ControlsView *)controlsView sliderStartedTracking:(float)value {
	if(!self.player) {return;}
	self.seeking = YES;
	rateBeforeSeek = self.player.rate;
	[self.player pause];
}

// stop seeking, restart playback
- (void)controlsView:(ControlsView *)controlsView sliderStoppedTracking:(float)value {
	if(!self.player) {return;}
	int duration = CMTimeGetSeconds(self.player.currentItem.duration);
    int elapsed = duration * value;
    [self.controlsView setElapsedTime:CMTimeMake(elapsed, 1) forDuration:self.player.currentItem.duration];
	[self.player seekToTime:CMTimeMakeWithSeconds(elapsed, 100) completionHandler:^(BOOL completed) {
		if(self->rateBeforeSeek > 0) {
			[self.player play];
		}
	}];
	self.seeking = NO;
}

// update value
- (void)controlsView:(ControlsView *)controlsView sliderValueChanged:(float)value {
	if(!self.player) {return;}
	int duration = CMTimeGetSeconds(self.player.currentItem.duration);
    int elapsed = duration * value;
    [self.controlsView setElapsedTime:CMTimeMake(elapsed, 1) forDuration:self.player.currentItem.duration];
}

#pragma mark Overridden Getters / Setters

// for iPhone, hide nav bar title as filename is displayed in info label
- (NSString *)name {
	return (Util.isDeviceATablet ? self.file.lastPathComponent : @"");
}

- (NSString *)type {
	return @"RecordingScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = UIColor.blackColor;
			
			// add views new parent view
			if(self.infoLabel) {
				[self.parentView addSubview:self.infoLabel];
			}
			if(self.background) {
				[self.parentView addSubview:self.background];
			}
			if(self.controlsView) {
				[self.parentView addSubview:self.controlsView];
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

- (BOOL)requiresOnscreenControls {
	return NO;
}

#pragma mark Util

+ (BOOL)isRecording:(NSString *)fullpath; {
	NSString *ext = fullpath.pathExtension;
	return [ext isEqualToString:@"wav"] || [ext isEqualToString:@"wave"] ||
	       [ext isEqualToString:@"aif"] || [ext isEqualToString:@"aiff"];
}

@end
