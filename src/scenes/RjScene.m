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
#import "RjScene.h"

@interface RjScene () {
	UIImageView *background;
}
@end

@implementation RjScene

+ (id)sceneWithParent:(UIView*)parent andControls:(UIView*)controls {
	RjScene *s = [[RjScene alloc] init];
	s.parentView = parent;
	s.controlsView = controls;
	return s;
}

- (id)init {
	self = [super init];
    if(self) {
		self.controlsView = nil;
    }
    return self;
}

- (BOOL)open:(NSString*)path {
	
	[PdBase addToSearchPath:[[Util documentsPath] stringByAppendingPathComponent:@"lib/rj"]];
	
	if([super open:[path stringByAppendingPathComponent:@"_main.pd"]]) {
			
		// set patch view background color
		self.parentView.backgroundColor = [UIColor blackColor];
		
		// set background
		NSString *backgroundPath = [path stringByAppendingPathComponent:@"image.jpg"];
		if([[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
			background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
			if(!background.image) {
				DDLogError(@"RjScene: couldn't load background image");
			}
			[self.parentView addSubview:background];
		}
		else {
			DDLogWarn(@"RjScene: no background image");
		}
		
		[self.parentView bringSubviewToFront:self.controlsView];
		self.controlsView.hidden = NO;
		
		[self reshape];
		
		// turn up volume & turn on transport
		[PureData sendVolume:1.0];
		[PureData sendPlay:YES];
		
		return YES;
	}
	
	return NO;
}

- (void)close {
	if(background) {
		[background removeFromSuperview];
		background = nil;
	}
	self.controlsView.hidden = YES;
	[super close];
}

- (void)reshape {
	CGSize viewSize, backgroundSize, controlsSize;
	CGFloat xPos = 0;
	
	// rj backgrounds are always square
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
	if(background) {
		background.frame = CGRectMake(xPos, 0, backgroundSize.width, backgroundSize.height);
	}
	
	// set controls
	controlsSize.width = backgroundSize.width;
	controlsSize.height = viewSize.height - backgroundSize.height;
	self.controlsView.frame = CGRectMake(0, backgroundSize.height, controlsSize.width, controlsSize.height);
}

- (BOOL)scaleTouch:(UITouch*)touch forPos:(CGPoint*)pos {
	CGPoint p = [touch locationInView:background];
	if(![background pointInside:p withEvent:nil]) {
		return NO;
	}
	// rj scenes require 320x320 coord system
	pos->x = (int) (pos->x/CGRectGetWidth(background.frame) * 320);
	pos->y = (int) (pos->y/CGRectGetHeight(background.frame) * 320);
	return YES;
}

#pragma mark Overridden Getters / Setters

- (SceneType)type {
	return SceneTypeRj;
}

- (NSString *)typeString {
	return @"RjScene";
}

- (int)sampleRate {
	return RJ_SAMPLERATE;
}

- (BOOL)requiresRotation {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

#pragma mark Util

+ (BOOL)isRjDjDirectory:(NSString *)fullpath {
	if([[fullpath pathExtension] isEqualToString:@"rj"] &&
		[[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"_main.pd"]]) {
		return YES;
	}
	return NO;
}

@end
