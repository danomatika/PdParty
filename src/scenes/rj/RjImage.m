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
#import "RjImage.h"

@implementation RjImage

+ (id)imageWithFile:(NSString *)path andParent:(RjScene *)parent {
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
		if(!iv.image) {
			DDLogError(@"RjImage: couldn't load: %@", path);
			return nil;
		}
		RjImage *image = [[RjImage alloc] initWithFrame:iv.frame];
		image.parentScene = parent;
		image.image = iv;
		image.originalFrame = iv.frame;
		image.frame = image.image.frame;
		[image addSubview:iv];
		[image reshape];
		return image;
	}
	else {
		DDLogWarn(@"RjImage: %@ not found", path);
	}
	return nil;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		_scaleX = 1.0f;
		_scaleY = 1.0f;
		_angle = 0.0f;
	}
	return self;
}

// TODO: edge antialiasing for rotations?
// http://stackoverflow.com/questions/1136110/any-quick-and-dirty-anti-aliasing-techniques-for-a-rotated-uiimageview
- (void)reshape {
	self.transform = CGAffineTransformIdentity;
	if(self.centered) {
		self.frame = CGRectMake(0, 0,
			round(self.originalFrame.size.width * self.parentScene.scale * self.scaleX),
			round(self.originalFrame.size.height * self.parentScene.scale * self.scaleY));
		self.center = CGPointMake(
			round(self.originalFrame.origin.x * self.parentScene.scale),
			round(self.originalFrame.origin.y * self.parentScene.scale));
	}
	else {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * self.parentScene.scale),
			round(self.originalFrame.origin.y * self.parentScene.scale),
			round(self.originalFrame.size.width * self.parentScene.scale * self.scaleX),
			round(self.originalFrame.size.height * self.parentScene.scale * self.scaleY));
	}
	self.image.frame = self.bounds;
	self.transform = CGAffineTransformMakeRotation(self.angle * (M_PI/180.f));
}

- (void)setScaleX:(float)sx andY:(float)sy {
	if(_scaleX == sx && _scaleY == sy) return;
	_scaleX = sx;
	_scaleY = sy;
	[self reshape];
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"RjImage";
}

- (void)setScaleX:(float)scaleX {
	if(_scaleX == scaleX) return;
	_scaleX = scaleX;
	[self reshape];
}

- (void)setScaleY:(float)scaleY {
	if(_scaleY == scaleY) return;
	_scaleY = scaleY;
	[self reshape];
}

- (void)setAngle:(float)angle {
	if(_angle == angle) return;
	_angle = angle;
	[self reshape];
}

@end
