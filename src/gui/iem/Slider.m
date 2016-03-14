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
#import "Slider.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@interface Slider () {
	BOOL isReversed; //< is the min value > max value?
	double sizeConvFactor; //< scaling factor for lin/log value conversion
	int centerValue; //< for detecting when to draw thicker control
	int controlPos; //< control movement calc
	BOOL isOneFinger; //< one finger or two?
	float prevPos; //< prev pos for delta calc
}
@property (readonly, nonatomic) int controlValue; //< slider int value, related to pos
- (void)checkSize;
- (void)checkMinAndMax;
@end

@implementation Slider

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 23) { // sanity check
		DDLogWarn(@"Slider: cannot create, atom line length < 23");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		isReversed = NO;
		sizeConvFactor = 0;
		isOneFinger = YES;
		prevPos = 0;
		self.multipleTouchEnabled = YES;
		self.log = NO;
		self.orientation = WidgetOrientationHorizontal;
		self.steady = YES;
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Slider: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
		
		self.minValue = [[line objectAtIndex:7] floatValue];
		self.maxValue = [[line objectAtIndex:8] floatValue];
		self.log = [[line objectAtIndex:9] boolValue];
		self.inits = [[line objectAtIndex:10] boolValue];
		[self checkMinAndMax];
		[self checkSize];
		
		self.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
		self.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue], [[line objectAtIndex:15] floatValue]);
		self.labelFontStyle = [[line objectAtIndex:16] intValue];
		self.labelFontSize = [[line objectAtIndex:17] floatValue];
		
		self.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] intValue]];
		self.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] intValue]];
		self.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] intValue]];
		
		if(self.inits) {
			self.controlValue = [[line objectAtIndex:21] intValue];
		}
		self.steady = [[line objectAtIndex:22] boolValue];
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
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1));
	
	// slider pos
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	CGContextSetShouldAntialias(context, NO); // no fuzzy straight lines
	if(self.orientation == WidgetOrientationHorizontal) {
		float x = (self.controlValue + 50) * 0.01 * self.gui.scaleX;
		int controlWidth = 3;
		// constrain pos at edges
		if(x < controlWidth) {
			x = controlWidth;
		}
		// width of slider control & pixel padding
		else if(x > rect.size.width - (controlWidth - 1)) {
			x = rect.size.width - controlWidth - 1;
		}
		else if (self.controlValue == centerValue) {
			controlWidth = 7; // thick line in middle
		}
		CGContextSetLineWidth(context, controlWidth);
		CGContextMoveToPoint(context, x, round(rect.origin.y));
		CGContextAddLineToPoint(context, x, round(rect.origin.y+rect.size.height-1));
		CGContextStrokePath(context);
	}
	else { // vertical
		float y = CGRectGetHeight(rect) - ((self.controlValue + 50) * 0.01 * self.gui.scaleX);
		int controlWidth = 3;
		// constrain pos at edges
		if(y < controlWidth) {
			y = controlWidth;
		}
		// height of slider control & pixel padding
		else if(y > rect.size.height - (controlWidth - 1)) {
			y = rect.size.height - controlWidth - 1;
		}
		else if(self.controlValue == centerValue) {
			controlWidth = 7; // thick line in middle
		}
		CGContextSetLineWidth(context, controlWidth);
		CGContextMoveToPoint(context, round(rect.origin.x), y);
		CGContextAddLineToPoint(context, round(rect.origin.x+rect.size.width-1), y);
		CGContextStrokePath(context);
	}
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value{
	double g;
	if(isReversed) {
		value = CLAMP(value, self.maxValue, self.minValue);
	}
	else {
		value = CLAMP(value, self.minValue, self.maxValue);
	}
	[super setValue:value];

	if(self.log) { // float to pos
		g = log(value / self.minValue) / sizeConvFactor;
	}
	else {
		g = (value - self.minValue) / sizeConvFactor;
	}
	_controlValue = (int)(100.0*g + 0.49999);
	controlPos = _controlValue;
}

- (void)setControlValue:(int)controlValue {
	_controlValue = controlValue;
	controlPos = controlValue;
	
	double g;
	if(self.log) { // pos to float
		g = self.minValue * exp(sizeConvFactor * (double)(controlValue) * 0.01);
	}
	else {
		g = (double)(controlValue) * 0.01 * sizeConvFactor + self.minValue;
	}
	
	if((g < 1.0e-10) && (g > -1.0e-10)) {
		g = 0.0;
	}
	[super setValue:g];
}

- (void)setOrientation:(WidgetOrientation)orientation {
	_orientation = orientation;
	[self checkMinAndMax];
	[self checkSize];
}

- (void)setLog:(BOOL)l {
	if(_log == l) return;
	_log = l;
	
	if(self.log) {
		[self checkMinAndMax];
	}
	else {
		float size = CGRectGetWidth(self.originalFrame);
		if(self.orientation == WidgetOrientationVertical) {
			size = CGRectGetHeight(self.originalFrame);
		}
		sizeConvFactor = (self.maxValue - self.minValue) / (double)(size - 1);
	}
}

- (NSString *)type {
	if(self.orientation == WidgetOrientationHorizontal) {
		return @"HSlider";
	}
	return @"VSlider";
}

#pragma mark Touches

// from g_hslider.c & g_vslider.c
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	
	if([touches count] > 1) {
		isOneFinger = NO;
	}
	else {
		isOneFinger = YES;
	}
	
	if(self.orientation == WidgetOrientationHorizontal) {
		
		if(!self.steady) {
			int v = (int)(100.0 * (pos.x / self.gui.scaleX));
			v = CLAMP(v, 0, (100 * CGRectGetWidth(self.originalFrame) - 100));
			self.controlValue = v;
		}
		
		[self sendFloat:self.value];
		prevPos = pos.x;
	}
	else if(self.orientation == WidgetOrientationVertical) {
		
		if(!self.steady) {
			int v = (int)(100.0 * ((CGRectGetHeight(self.frame)-pos.y) / self.gui.scaleX));
			v = CLAMP(v, 0, (100 * CGRectGetHeight(self.originalFrame) - 100));
			self.controlValue = v;
		}
		
		[self sendFloat:self.value];
		prevPos = pos.y;
	}
}

// from g_hslider.c & g_vslider.c
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	
	if(self.orientation == WidgetOrientationHorizontal) {
		float delta = (pos.x - prevPos) / self.gui.scaleX;
		float old = self.controlValue;
	
		int v = 0;
		if(!isOneFinger) {
			controlPos += (int)delta;
		}
		else {
			controlPos += 100 * (int)delta;
		}
		v = controlPos;
		
		if(v > (100 * CGRectGetWidth(self.originalFrame) - 100)) {
			v = 100 * CGRectGetWidth(self.originalFrame) - 100;
			controlPos += 50;
			controlPos -= controlPos % 100;
		}
		if(v < 0) {
			v = 0;
			controlPos -= 50;
			controlPos -= controlPos % 100;
		}
		self.controlValue = v;
		
		// don't resend old values
		if(old != v) {
			[self sendFloat:self.value];
		}
		
		prevPos = pos.x;
	}
	else if(self.orientation == WidgetOrientationVertical) {
		float delta = (pos.y - prevPos) / self.gui.scaleX;
		float old = self.controlValue;
	
		int v = 0;
		if(!isOneFinger) {
			controlPos += (int)delta;
		}
		else {
			controlPos -= 100 * (int)delta;
		}
		v = controlPos;
		
		if(v > (100 * CGRectGetHeight(self.originalFrame) - 100)) {
			v = 100 * CGRectGetHeight(self.originalFrame) - 100;
			controlPos += 50;
			controlPos -= controlPos % 100;
		}
		if(v < 0) {
			v = 0;
			controlPos -= 50;
			controlPos -= controlPos % 100;
		}
		self.controlValue = v;
		controlPos = v;
		
		// don't resend old values
		if(old != v) {
			[self sendFloat:self.value];
		}
		
		prevPos = pos.y;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	isOneFinger = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	isOneFinger = YES;
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
	if([message isEqualToString:@"size"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// width, height
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([[arguments objectAtIndex:1] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		[self checkSize];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"steady"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		self.steady = [[arguments objectAtIndex:0] boolValue];
		return YES;
	}
	else if([message isEqualToString:@"range"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// low, high
		self.minValue = [[arguments objectAtIndex:0] floatValue];
		self.maxValue = [[arguments objectAtIndex:1] floatValue];
		[self checkMinAndMax];
		return YES;
	}
	else if([message isEqualToString:@"lin"]) {
		self.log = NO;
		return YES;
	}
	else if([message isEqualToString:@"log"]) {
		self.log = YES;
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

#pragma mark Private

// from g_hslider.c & g_vslider.c
- (void)checkSize {
	float size = CGRectGetWidth(self.originalFrame);
	if(self.orientation == WidgetOrientationVertical) {
		size = CGRectGetHeight(self.originalFrame);
	}

	if(size < IEM_SL_MINSIZE) {
		size = IEM_SL_MINSIZE;
		if(self.orientation == WidgetOrientationHorizontal) {
			self.originalFrame = CGRectMake(
				self.originalFrame.origin.x, self.originalFrame.origin.y,
				size, CGRectGetHeight(self.originalFrame));
		}
		else if(self.orientation == WidgetOrientationVertical) {
			self.originalFrame = CGRectMake(
				self.originalFrame.origin.x, self.originalFrame.origin.y,
				CGRectGetWidth(self.originalFrame), size);
		}
	}
	
	centerValue = (size-1) * 50;
	if(self.controlValue > (size * 100 - 100)) {
		self.controlValue = size * 100 - 100;
	}
	if(self.log) {
		sizeConvFactor = log(self.maxValue / self.minValue) / (double)(size - 1);
	}
	else {
		sizeConvFactor = (self.maxValue - self.minValue) / (double)(size - 1);
	}
}

// from g_hslider.c & g_vslider.c
- (void)checkMinAndMax {
	if(self.log) {
		if((self.minValue == 0.0) && (self.maxValue == 0.0)) {
			self.maxValue = 1.0;
		}
		if(self.maxValue > 0.0) {
			if(self.minValue <= 0.0) {
				self.minValue = 0.01 * self.maxValue;
			}
		}
		else {
			if(self.minValue > 0.0) {
				self.maxValue = 0.01 * self.minValue;
			}
		}
	}

	if(self.minValue > self.maxValue) {
		isReversed = YES;
	}
	else {
		isReversed = NO;
	}
	
	float size = CGRectGetWidth(self.originalFrame);
	if(self.orientation == WidgetOrientationVertical) {
		size = CGRectGetHeight(self.originalFrame);
	}
	
	if(self.log) {
		sizeConvFactor = log(self.maxValue / self.minValue) / (double)(size - 1);
	}
	else {
		sizeConvFactor = (self.maxValue - self.minValue) / (double)(size - 1);
	}
}

@end
