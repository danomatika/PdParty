/*
 * Copyright (c) 2022 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PatchView.h"

#import "PatchViewController.h"
#import "Log.h"

@implementation PatchView

- (void)awakeFromNib {
	[super awakeFromNib];
	self.multipleTouchEnabled = YES;
}

#pragma mark Overridden Getters / Setters

- (void)setRotation:(int)rotation {
	if(rotation == _rotation) {
		return;
	}
	_rotation = rotation;
	if(self.rotation == 0) {
		if(!CGAffineTransformIsIdentity(self.transform)) {
			LogVerbose(@"PatchView: rotating view back to 0");
			self.transform = CGAffineTransformIdentity;
			self.bounds = CGRectMake(0, 0,
				CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));
		}
	}
	else {
		if(CGAffineTransformIsIdentity(self.transform)) {
			LogVerbose(@"PatchView: rotating view to %d", self.rotation);
			self.transform = CGAffineTransformMakeRotation(self.rotation / 180.0 * M_PI);
			self.bounds = CGRectMake(0, 0,
				CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));
		}
	}
}

#pragma mark Touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if(self.touchResponder) {
		[self.touchResponder touchesBegan:touches withEvent:event];
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if(self.touchResponder) {
		[self.touchResponder touchesMoved:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if(self.touchResponder) {
		[self.touchResponder touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if(self.touchResponder) {
		[self.touchResponder touchesCancelled:touches withEvent:event];
	}
}

@end
