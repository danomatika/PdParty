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

+ (id)radioFromAtomLine:(NSArray *)line withOrientation:(WidgetOrientation)orientation withGui:(Gui *)gui {

	if(line.count < 19) { // sanity check
		DDLogWarn(@"Radio: cannot create, atom line length < 19");
		return nil;
	}

	Radio *r = [[Radio alloc] initWithFrame:CGRectZero];

	r.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
	r.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
	if(![r hasValidSendName] && ![r hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Radio: dropping, send/receive names are empty");
		return nil;
	}
	
	r.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on numCells
			
	r.orientation = orientation;
	r.size = [[line objectAtIndex:5] integerValue];
	r.value = [[line objectAtIndex:6] integerValue];
	r.inits = [[line objectAtIndex:7] boolValue];
	r.numCells = [[line objectAtIndex:8] integerValue];
	
	r.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
	r.originalLabelPos = CGPointMake([[line objectAtIndex:12] floatValue], [[line objectAtIndex:13] floatValue]);
	r.labelFontSize = [[line objectAtIndex:15] floatValue];
	
	r.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	r.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:17] integerValue]];
	r.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] integerValue]];

	r.gui = gui;
	
	return r;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.size = IEM_GUI_DEFAULTSIZE;
		_numCells = 8; // don't trigger redraw yet
		self.minValue = 0;
		self.orientation = WidgetOrientationHorizontal;
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
	CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
	
	// cells
	int cellSize = round(self.size * self.gui.scaleX);
	for(int i = 0; i < self.numCells; ++i) {
	
		// bounds
		CGRect cellRect;
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
			int buttonSize = round(cellSize/4);
			CGRect buttonRect = CGRectMake(round(cellRect.origin.x + buttonSize),
										   round(cellRect.origin.y + buttonSize),
										   round(cellSize/2), round(cellSize/2));
			CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
			CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
			CGContextFillRect(context, buttonRect);
			CGContextStrokeRect(context, buttonRect);
		}
	}
}

- (void)reshapeForGui:(Gui *)gui {
	
	float cellSize = round(self.size * gui.scaleX);
	
	// bounds
	if(self.orientation == WidgetOrientationHorizontal) {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * gui.scaleX),
			round(self.originalFrame.origin.y * gui.scaleY),
			round(self.numCells * cellSize) + 1, cellSize);
	}
	else {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * gui.scaleX),
			round(self.originalFrame.origin.y * gui.scaleY),
			cellSize, round(self.numCells * cellSize) + 1);
	}
	
	// label
	[self reshapeLabelForGui:gui];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	int newVal = (int) MIN(self.maxValue, MAX(self.minValue, f)); // round to int
	[super setValue:newVal];
}

- (void)setSize:(int)size {
	_size = MAX(size, IEM_GUI_MINSIZE);
	[self setNeedsDisplay]; // redraw with new width
}

- (void)setNumCells:(int)numCells {
	if(numCells < 1) {
		numCells = 1;
	}
	if(numCells > IEM_RADIO_MAX) {
		numCells = IEM_RADIO_MAX;
	}
	_numCells = numCells;
	self.maxValue = numCells - 1;
	if(numCells - 1 < self.value) {
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
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	if(self.orientation == WidgetOrientationHorizontal) {
		self.value = pos.x/round(self.size * self.gui.scaleX);
	}
	else {
		self.value = pos.y/round(self.size * self.gui.scaleX);
	}
	[self sendFloat:self.value];
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {

	if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// size
		self.size = [[arguments objectAtIndex:0] integerValue];
		[self reshapeForGui:self.gui];
		[self setNeedsDisplay];
		return YES;
	}
	if([message isEqualToString:@"number"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// number of cells
		self.numCells = [[arguments objectAtIndex:0] integerValue];
		[self reshapeForGui:self.gui];
		[self setNeedsDisplay];
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

@end
