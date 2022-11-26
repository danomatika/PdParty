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
		
		self.sendName = [Gui filterEmptyStringValues:line[8]];
		self.receiveName = [Gui filterEmptyStringValues:line[7]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Numberbox: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[5] floatValue], [line[6] floatValue]);

		self.valueWidth = 3; // fixed width
		self.minValue = [line[9] floatValue];
		self.maxValue = [line[10] floatValue];
		self.inits = YES;
		
		if([line count] > 10) {
			self.value = [line[11] floatValue];
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

	// bounds (from Widget)
	self.frame = CGRectMake(
		round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
		round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleWidth),
		round(self.originalFrame.size.height * self.gui.scaleHeight));
	
	// value label
	[self reshapeValueLabel];
}

- (void)reshapeValueLabel {
	self.valueLabel.font = [UIFont fontWithName:self.gui.fontName size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.valueLabel.font}]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth = ceil(charSize.width) * (self.valueWidth == 0 ? 3 : self.valueWidth);
	[self.valueLabel sizeToFit];
	self.valueLabel.center = CGPointMake(round(CGRectGetWidth(self.frame)/2), round(CGRectGetHeight(self.frame)/2));
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
