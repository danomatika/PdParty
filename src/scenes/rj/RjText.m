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
 #import "RjText.h"

@implementation RjText

+ (id)textWithText:(NSString *)text andParent:(RjScene *)parent {
	RjText *t = [[RjText alloc] initWithFrame:CGRectZero];
	t.parentScene = parent;
	t.text = text;
	return t;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		_fontSize = 12;
		
		self.label = [[UILabel alloc] initWithFrame:CGRectZero];
		self.label.text = @"empty";
		self.label.backgroundColor = [UIColor clearColor];
		self.label.textColor = WIDGET_FRAME_COLOR;
		self.label.textAlignment = NSTextAlignmentLeft;
		[self addSubview:self.label];
    }
    return self;
}

- (void)reshape {

	// label
	self.label.font = [UIFont fontWithName:self.parentScene.gui.fontName size:self.fontSize * self.parentScene.scale];
	[self.label sizeToFit];
	
	// bounds based on computed label size
	if(self.centered) {
		self.frame = CGRectMake(0, 0,
			round(CGRectGetWidth(self.label.frame)),
			round(CGRectGetHeight(self.label.frame)));
		self.center = CGPointMake(
			round(self.originalFrame.origin.x * self.parentScene.scale),
			round(self.originalFrame.origin.y * self.parentScene.scale));
	}
	else {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * self.parentScene.scale),
			round(self.originalFrame.origin.y * self.parentScene.scale),
			round(CGRectGetWidth(self.label.frame)),
			round(CGRectGetHeight(self.label.frame)));
	}
	
	// fix blurry label text
	// http://thinketg.com/ios-tip-fixing-blurry-text-anti-aliasing-in-your-ipadiphone-app
	self.frame = CGRectIntegral(self.frame);
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"RjText";
}

- (void)setText:(NSString *)text {
	if([self.label.text isEqualToString:text]) return;
	self.label.text = text;
	[self reshape];
}

- (NSString *)text {
	return self.label.text;
}

- (void)setFontSize:(float)fontSize {
	if(_fontSize == fontSize) return;
	_fontSize = fontSize;
	[self reshape];
}

@end
