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
#import "AtomWidget.h"

#import "Gui.h"

@implementation AtomWidget

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.valueLabel setTextAlignment:NSTextAlignmentLeft];
		self.valueLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.valueLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextSetLineWidth(context, 1.0);
	
    CGRect frame = rect;
	
	// border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, frame.size.width-8, 0);
    CGContextAddLineToPoint(context, frame.size.width-1, 8);
	CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, 0);
    CGContextStrokePath(context);
}

- (void)reshapeForGui:(Gui *)gui {
	
	// bounds
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		round(((self.valueWidth) * (gui.fontSize))),
		round((gui.labelFontSize + 8)));
		
	// value label
	self.valueLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.labelFontSize];
	self.valueLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.frame);
	self.valueLabel.frame = CGRectMake(1, 1, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.labelFontSize];
	[self.label sizeToFit];
		
	// set the label pos from the LRUD setting
	int labelPosX, labelPosY;
	switch(self.labelPos) {
		default: // 0 LEFT
			labelPosX = -self.label.frame.size.width - 2;
			labelPosY = 2;
			break;
		case 1: // RIGHT
			labelPosX = self.frame.size.width + 2;
			labelPosY = 2;
			break;
		case 2: // TOP
			labelPosX = 0;
			labelPosY = -self.label.frame.size.height - 2;
			break;
		case 3: // BOTTOM
			labelPosX = 0;
			labelPosY = self.frame.size.height + 2;
			break;
	}
	
	self.label.frame = CGRectMake(labelPosX, labelPosY,
		CGRectGetWidth(self.label.frame), CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"AtomWidget";
}

@end
