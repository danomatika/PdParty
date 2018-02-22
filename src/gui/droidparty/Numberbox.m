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
#import "Numberbox.h"

#import "Gui.h"

@interface Numberbox () {
	BOOL touchDown;
}
@end

@implementation Numberbox

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 10) { // sanity check
		DDLogWarn(@"Numberbox: cannot create, atom line length < 10");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		touchDown = NO;
		self.valueLabel.textAlignment = NSTextAlignmentCenter;
		
		// don't need the label
		[self.label removeFromSuperview];
		self.label = nil;
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Numberbox: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);

		self.valueWidth = 3; // fixed width
		self.minValue = [[line objectAtIndex:9] floatValue];
		self.maxValue = [[line objectAtIndex:10] floatValue];
		self.inits = YES;
		
		if ([line count] > 10) {
			self.value = [[line objectAtIndex:11] floatValue];
		}
		else {
			self.value = 0; // set text in number label
		}
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillRect(context, rect);
	
	// border
	if(touchDown) {
		CGContextSetLineWidth(context, 2.0);
	}
	else {
		CGContextSetLineWidth(context, 1.0);
	}
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
}

- (void)reshape {

	// bounds (from Widget)
	self.frame = CGRectMake(
		roundf(self.originalFrame.origin.x * self.gui.scaleX + self.gui.offsetX),
		roundf(self.originalFrame.origin.y * self.gui.scaleY + self.gui.offsetY),
		roundf(self.originalFrame.size.width * self.gui.scaleX),
		roundf(self.originalFrame.size.height * self.gui.scaleY));
	
	// value label
	[self reshapeValueLabel];
}

- (void)reshapeValueLabel {
	self.valueLabel.font = [UIFont fontWithName:self.gui.fontName size:(int)roundf(CGRectGetHeight(self.frame) * 0.75)];
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.valueLabel.font}]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth = ceilf(charSize.width) * (self.valueWidth == 0 ? 3 : self.valueWidth);
	[self.valueLabel sizeToFit];
	self.valueLabel.center = CGPointMake(roundf(CGRectGetWidth(self.frame)/2), roundf(CGRectGetHeight(self.frame)/2));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	[super setValue:value];
}

- (NSString *)type {
	return @"Numberbox";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	touchDown = YES;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	touchDown = NO;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	touchDown = NO;
	[self setNeedsDisplay];
}

#pragma mark WidgetListener

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self setNeedsDisplay];
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (void)receiveSetSymbol:(NSString *)symbol {
	// swallows set symbols
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	// swallow range message sent by droidparty numberbox.pd abstraction
	if([message isEqualToString:@"range"]) {
		return YES;
	}
	return NO;
}

@end
