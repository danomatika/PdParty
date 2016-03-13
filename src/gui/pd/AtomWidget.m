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

@interface AtomWidget () {
	int cornerSize; //< bent corner pixel size
}
@end

@implementation AtomWidget

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.valueLabel.textAlignment = NSTextAlignmentLeft;
		self.valueLabel.lineBreakMode = NSLineBreakByClipping;
		self.valueLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.valueLabel];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);

	// bounds as path
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-cornerSize, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, cornerSize);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, 0);
	
	// background
	CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	
	CGPathRelease(path);
}

- (void)reshape {
	
	// value label
	self.valueLabel.font = [UIFont fontWithName:self.gui.fontName size:self.gui.fontSize * self.gui.scaleX];
	CGSize charSize = [@"0" sizeWithFont:self.valueLabel.font]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth = charSize.width * self.valueWidth;
	[self.valueLabel sizeToFit];
	CGRect valueLabelFrame = self.valueLabel.frame;
	if(self.valueWidth > 0) {
		if(valueLabelFrame.size.width < self.valueLabel.preferredMaxLayoutWidth) {
			// make sure width matches valueWidth
			valueLabelFrame.size.width = self.valueLabel.preferredMaxLayoutWidth;
		}
	}
	else if(valueLabelFrame.size.width < charSize.width*3) { // min zero width of 3
		valueLabelFrame.size.width = charSize.width*3;
	}
	valueLabelFrame.origin = CGPointMake(round(self.gui.scaleX), round(self.gui.scaleX));
	self.valueLabel.frame = valueLabelFrame;
	
	// bounds from value label size, zero width atoms are slightly taller
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * self.gui.scaleX),
		round(self.originalFrame.origin.y * self.gui.scaleY),
		round(CGRectGetWidth(self.valueLabel.frame) + (3 * self.gui.scaleX)),
		round(CGRectGetHeight(self.valueLabel.frame) + ((self.valueWidth == 0 ? 3 : 2) * self.gui.scaleX)));
	cornerSize = 4 * self.gui.scaleX;

	// label
	self.label.font = [UIFont fontWithName:self.gui.fontName size:self.gui.fontSize * self.gui.scaleX];
	[self.label sizeToFit];
		
	// set the label pos from the LRUD setting
	int labelPosX, labelPosY;
	switch(self.labelPos) {
		default: // 0 LEFT
			labelPosX = -self.label.frame.size.width - (2 * self.gui.scaleX);
			labelPosY = 2 * self.gui.scaleX;
			break;
		case 1: // RIGHT
			labelPosX = self.frame.size.width + (2 * self.gui.scaleX);
			labelPosY = 2 * self.gui.scaleX;
			break;
		case 2: // TOP
			labelPosX = 0;
			labelPosY = -self.label.frame.size.height - (2 * self.gui.scaleX);
			break;
		case 3: // BOTTOM
			labelPosX = 0;
			labelPosY = self.frame.size.height + (2 * self.gui.scaleX);
			break;
	}
	
	self.label.frame = CGRectMake(labelPosX, labelPosY,
		CGRectGetWidth(self.label.frame), CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.valueWidth == 0 && self.gui) {
		[self reshape];
	}
	[super setValue:value];
}

- (void)setValueWidth:(int)valueWidth {
	_valueWidth = MAX(valueWidth, 0);
	if(self.valueWidth == 0 && self.gui) {
		[self reshape];
		[self setNeedsDisplay];
	}
}

- (NSString *)type {
	return @"AtomWidget";
}

@end
