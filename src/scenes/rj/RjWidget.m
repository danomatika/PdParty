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
		self.autoresizesSubviews = NO;
		self.hidden = NO;
		_centered = YES;
	}
	return self;
}

- (void)dealloc {
	[self removeFromSuperview];
}

- (void)reshape {
	// implement in subclasses
}

#pragma mark Overridden Getters / Setters

- (void)setPosition:(CGPoint)p {
	self.originalFrame = CGRectMake(p.x, p.y,
							CGRectGetWidth(self.originalFrame),
							CGRectGetHeight(self.originalFrame));
	[self reshape];
}

- (CGPoint)position {
	return self.originalFrame.origin;
}

- (void)setCentered:(BOOL)centered {
	if(_centered == centered) return;
	_centered = centered;
	[self reshape];
}

@end
