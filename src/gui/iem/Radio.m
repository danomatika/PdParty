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
#import "Radio.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@implementation Radio

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 19) { // sanity check
		LogWarn(@"Radio: cannot create, atom line length < 19");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		_numCells = 8; // don't trigger redraw yet
		self.orientation = WidgetOrientationHorizontal;
		self.size = 15; // was IEM_GUI_DEFAULTSIZE until 0.53-0 changed macro
		self.minValue = 0;
		
		self.sendName = [Gui filterEmptyStringValues:line[9]];
		self.receiveName = [Gui filterEmptyStringValues:line[10]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			LogVerbose(@"Radio: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			0, 0); // size based on numCells
		
		self.size = [line[5] intValue];
		// index 6 is the "new_old" value which isn't currently used
		self.inits = [line[7] boolValue];
		self.numCells = [line[8] intValue];
		
		self.label.text = [Gui filterEmptyStringValues:line[11]];
		self.originalLabelPos = CGPointMake([line[12] floatValue], [line[13] floatValue]);
		self.labelFontStyle = [line[14] intValue];
		self.labelFontSize = [line[15] floatValue];
		
		self.fillColor = [IEMWidget colorFromAtomColor:line[16]];
		self.controlColor = [IEMWidget colorFromAtomColor:line[17]];
		self.label.textColor = [IEMWidget colorFromAtomColor:line[18]];
		
		if(self.inits) {
			self.value = [line[19] intValue];
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
	CGContextSetFillColorWithColor(context, UIColor.clearColor.CGColor);
	
	// cells
	int cellSize = round(self.size * self.gui.scaleWidth);
	for(int i = 0; i < self.numCells; ++i) {
	
		// bounds
		CGRect cellRect = CGRectZero;;
		if(self.orientation == WidgetOrientationHorizontal) {
			cellRect = CGRectMake(i*cellSize, 0, cellSize, cellSize - 1);
		}
		else if(self.orientation == WidgetOrientationVertical) {
			cellRect = CGRectMake(0, i*cellSize, cellSize - 1, cellSize);
		}
	
		// border
		CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
		CGContextStrokeRect(context, cellRect);
		
		// selected?
		if(i == (int)self.value) {
			int buttonSize = floor(cellSize*0.25);
			CGRect buttonRect = CGRectMake(floor(cellRect.origin.x + buttonSize),
			                               floor(cellRect.origin.y + buttonSize),
			                               ceil(cellSize*0.5), ceil(cellSize*0.5));
			CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
			CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
			CGContextFillRect(context, buttonRect);
			CGContextStrokeRect(context, buttonRect);
		}
	}
}

- (void)reshape {
	float cellSize = round(self.size * self.gui.scaleWidth);
	
	// bounds
	if(self.orientation == WidgetOrientationHorizontal) {
		self.frame = CGRectMake(
			round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
			round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
			round(self.numCells * cellSize) + 1, cellSize);
	}
	else {
		self.frame = CGRectMake(
			round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
			round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
			cellSize, round(self.numCells * cellSize) + 1);
	}
	
	// label
	[self reshapeLabel];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	int newVal = (int) CLAMP(f, self.minValue, self.maxValue); // round to int
	[super setValue:newVal];
}

- (void)setSize:(int)size {
	_size = MAX(size, IEM_GUI_MINSIZE);
	[self setNeedsDisplay]; // redraw with new width
}

- (void)setNumCells:(int)numCells {
	_numCells = CLAMP(numCells, 1, IEM_RADIO_MAX);
	self.maxValue = _numCells - 1;
	if(self.maxValue < self.value) {
		self.value = self.maxValue;
	}
}

- (NSString *)type {
	if(self.orientation == WidgetOrientationHorizontal) {
		return @"HRadio";
	}
	return @"VRadio";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	if(self.orientation == WidgetOrientationHorizontal) {
		self.value = pos.x/round(self.size * self.gui.scaleWidth);
	}
	else {
		self.value = pos.y/round(self.size * self.gui.scaleWidth);
	}
	[self sendFloat:self.value];
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[super sendFloat:received]; // Pd 0.46+ doesn't clip incoming values
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// size
		self.size = [arguments[0] intValue];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	if([message isEqualToString:@"number"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// number of cells
		self.numCells = [arguments[0] intValue];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

@end
