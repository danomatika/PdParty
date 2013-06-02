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
		[Util logRect:iv.frame];
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
		self.centered = NO;
		self.scaleX = 1.0f;
		self.scaleY = 1.0f;
    }
    return self;
}

- (void)reshape {
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * self.parentScene.scale),
		round(self.originalFrame.origin.y * self.parentScene.scale),
		round(self.originalFrame.size.width * self.parentScene.scale * self.scaleX),
		round(self.originalFrame.size.height * self.parentScene.scale * self.scaleY));
	if(self.centered) {
		self.center = CGPointMake(
			round(self.originalFrame.origin.x * self.parentScene.scale),
			round(self.originalFrame.origin.y * self.parentScene.scale));
	}
	self.image.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

- (void)setScaleX:(float)sx andY:(float)sy {
	if(self.scaleX == sx && self.scaleY == sy) return;
	self.scaleX = sx;
	self.scaleY = sy;
	[self reshape];
}

#pragma mark Overridden Getters / Setters

- (void)setCentered:(BOOL)centered {
	if(_centered == centered) return;
	[self reshape];
}

- (void)setAngle:(float)angle {
	self.transform = CGAffineTransformMakeRotation(angle * (180/M_PI));
}

- (NSString*)typeString {
	return @"RjImage";
}

@end