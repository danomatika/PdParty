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
#import "RjWidget.h"

@implementation RjWidget

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
    if(self) {
		self.hidden = YES; // hidden by default?
    }
    return self;
}

- (void)dealloc {
	[self removeFromSuperview];
}

- (void)reshape {
//	self.frame = CGRectMake(
//		round(self.originalFrame.origin.x * self.parentScene.scale),
//		round(self.originalFrame.origin.y * self.parentScene.scale),
//		round(self.originalFrame.size.width * self.parentScene.scale),
//		round(self.originalFrame.size.height * self.parentScene.scale));
}

#pragma mark Overridden Getters / Setters

- (void)setPosition:(CGPoint)p {
	self.originalFrame = CGRectMake(p.x, p.y,
							CGRectGetWidth(self.originalFrame),
							CGRectGetHeight(self.originalFrame));
//	self.frame = CGRectMake(p.x * self.parentScene.scale,
//							p.y * self.parentScene.scale,
//							CGRectGetWidth(self.frame),
//							CGRectGetHeight(self.frame));
	[self reshape];
}

- (CGPoint)position {
	return self.originalFrame.origin;
}

@end
