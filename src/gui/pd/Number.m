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
#import "Number.h"

#import "Gui.h"

@interface Number () {
	int touchPrevY;
	bool isOneFinger;
}
@end

@implementation Number

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 11) { // sanity check
		DDLogWarn(@"Numberbox: cannot create, atom line length < 11");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.multipleTouchEnabled = YES;
		touchPrevY = 0;
		isOneFinger = YES;
		
		self.sendName = [Gui filterEmptyStringValues:line[10]];
		self.receiveName = [Gui filterEmptyStringValues:line[9]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Numberbox: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			0, 0); // size based on valueWidth

		self.valueWidth = [line[4] intValue];
		self.minValue = [line[5] floatValue];
		self.maxValue = [line[6] floatValue];
		self.value = 0; // set text in number label
			
		self.labelPos = [line[7] intValue];
		self.label.text = [Gui filterEmptyStringValues:line[8]];
	}
	return self;
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	self.valueLabel.text = [Widget stringFromFloat:value withWidth:(self.valueWidth > 0 ? self.valueWidth : INT_MAX)];
	[super setValue:value];
}

- (void)setValueWidth:(int)valueWidth {
	self.valueLabel.text = [Widget stringFromFloat:self.value withWidth:(valueWidth > 0 ? valueWidth : INT_MAX)];
	[super setValueWidth:valueWidth];
}

- (NSString *)type {
	return @"Number";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	touchPrevY = pos.y;
	if(touches.count > 1) {
		isOneFinger = NO;
	}
	else {
		isOneFinger = YES;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	int diff = touchPrevY - pos.y;
	if(diff != 0) {
		float value = 0;
		if(isOneFinger) {
			value = self.value + diff;
		}
		else {
			// mult & divide by ints to avoid float rounding errors ...
			value = ((self.value*100) + (double) ((diff * 10) / 1000.f)*100)/100;
		}
		self.value = [self clampValue:value];
		[self sendFloat:self.value];
	}
	touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
	isOneFinger = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
	isOneFinger = YES;
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

#pragma mark Private

- (float)clampValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		return CLAMP(value, self.minValue, self.maxValue);
	}
	return value;
}

@end
