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
	int touchPrevY;
}
@end

@implementation Numberbox

+ (id)numberboxFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 11) { // sanity check
		DDLogWarn(@"Numberbox: Cannot create, atom line length < 11");
		return nil;
	}

	Numberbox *n = [[Numberbox alloc] initWithFrame:CGRectZero];

	n.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
	n.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
	if(![n hasValidSendName] && ![n hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Numberbox: Dropping, send/receive names are empty");
		return nil;
	}
	
	n.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on valueWidth

	n.valueWidth = [[line objectAtIndex:4] integerValue];
	n.minValue = [[line objectAtIndex:5] floatValue];
	n.maxValue = [[line objectAtIndex:6] floatValue];
	n.value = 0; // set text in number label
		
	n.labelPos = [[line objectAtIndex:7] integerValue];
	n.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:8]];

	[n reshapeForGui:gui];

	return n;
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = MIN(self.maxValue, MAX(value, self.minValue));
	}
	self.valueLabel.text = [Widget stringFromFloat:value withWidth:self.valueWidth];
	[super setValue:value];
}

- (void)setValueWidth:(int)valueWidth {
	[super setValueWidth:valueWidth];
	self.valueLabel.text = [Widget stringFromFloat:self.value withWidth:self.valueWidth];
}

- (NSString *)type {
	return @"Numberbox";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	touchPrevY = pos.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	int diff = touchPrevY - pos.y;
	if(diff != 0) {
		self.value = self.value + diff;
		[self sendFloat:self.value];
	}
	touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	self.value = 0;
	[self sendFloat:self.value];
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (void)receiveSetSymbol:(NSString *)symbol {
	// swallows set symbols
}

@end
