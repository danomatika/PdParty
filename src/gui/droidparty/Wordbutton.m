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
#import "Wordbutton.h"

#import "Gui.h"

@interface Wordbutton () {
	BOOL touchDown;
}
@end

@implementation Wordbutton

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 7) { // sanity check
		LogWarn(@"Wordbutton: cannot create, atom line length < 7");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		touchDown = NO;
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.label.adjustsFontSizeToFitWidth = YES;
		self.label.numberOfLines = 0;
		
		self.sendName = [@"wordbutton-" stringByAppendingString:[Gui filterEmptyStringValues:line[7]]];
		if(![self hasValidSendName]) {
			// drop something we can't interact with
			LogVerbose(@"Wordbutton: dropping, send name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[5] floatValue], [line[6] floatValue]);
		
		self.label.text = [Gui filterEmptyStringValues:line[7]];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, self.gui.lineWidth);
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillRect(context, rect);
	
	// border
	if(touchDown) {
		CGContextSetLineWidth(context, self.gui.lineWidth * 2.0);
	}
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
}

- (void)reshape {

	// bounds
	[super reshape];

	// label
	self.label.font = [UIFont fontWithName:self.gui.fontName size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	self.label.preferredMaxLayoutWidth = round(CGRectGetWidth(self.frame) * 0.75);
	[self.label sizeToFit];
	self.label.center = CGPointMake(round(CGRectGetWidth(self.frame)/2), round(CGRectGetHeight(self.frame)/2));
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Wordbutton";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	touchDown = YES;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	[self sendBang];
	touchDown = NO;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	touchDown = NO;
	[self setNeedsDisplay];
}

@end
