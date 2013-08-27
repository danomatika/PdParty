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
	BOOL isReversed; // is the min value > max value?
	double sizeConvFactor; // scaling factor for lin/log value conversion
	int centerValue; // for detecting when to draw thicker control
	int controlPos;
	BOOL isOneFinger;
	float prevPos;
}

- (void)checkSize;
- (void)checkMinAndMax;

@end

@implementation Slider

+ (id)sliderFromAtomLine:(NSArray *)line withOrientation:(WidgetOrientation)orientation withGui:(Gui *)gui {

	if(line.count < 23) { // sanity check
		DDLogWarn(@"Slider: cannot create, atom line length < 23");
		return nil;
	}

	Slider *s = [[Slider alloc] initWithFrame:CGRectZero];
	
	s.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
	s.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
	if(![s hasValidSendName] && ![s hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Slider: dropping, send/receive names are empty");
		return nil;
	}
	
	s.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	
	s.orientation = orientation;
	s.minValue = [[line objectAtIndex:7] floatValue];
	s.maxValue = [[line objectAtIndex:8] floatValue];
	s.log = [[line objectAtIndex:9] boolValue];
	s.inits = [[line objectAtIndex:10] boolValue];
	[s checkMinAndMax];
	[s checkSize];
	
	s.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
	s.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue], [[line objectAtIndex:15] floatValue]);
	s.labelFontSize = [[line objectAtIndex:17] floatValue];
	
	s.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] integerValue]];
	s.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] integerValue]];
	s.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] integerValue]];

	[s reshapeForGui:gui];
	s.gui = gui;
	
	if(orientation == WidgetOrientationHorizontal) {
		s.value = ([[line objectAtIndex:21] floatValue] * 0.01 * (s.maxValue - s.minValue)) /
			[[line objectAtIndex:5] floatValue];
	}
	else {
		s.value = ([[line objectAtIndex:21] floatValue] * 0.01 * (s.maxValue - s.minValue)) /
			([[line objectAtIndex:6] floatValue] - 1 + s.minValue);
	}
	
	if([line count] > 21 && [line isNumberAt:22]) {
		s.steady = [[line objectAtIndex:22] boolValue];
	}
	
	return s;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.log = NO;
		self.orientation = WidgetOrientationHorizontal;
		self.steady = YES;
		isReversed = NO;
		sizeConvFactor = 0;
		isOneFinger = YES;
		prevPos = 0;
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
		float x = rect.origin.x + (self.value + 50) * 0.01 * self.gui.scaleX;
		int controlWidth = 3;
		// constrain pos at edges
		if(x < controlWidth) {
			x = controlWidth;
		}
		// width of slider control & pixel padding
		else if(x > rect.size.width - (controlWidth - 1)) {
			x = rect.size.width - controlWidth - 1;
		}
		else if (self.value == centerValue) {
			controlWidth = 7; // thick line in middle
		}
		CGContextSetLineWidth(context, controlWidth);
		CGContextMoveToPoint(context, x, round(rect.origin.y));
		CGContextAddLineToPoint(context, x, round(rect.origin.y+rect.size.height-1));
		CGContextStrokePath(context);
	}
	else { // vertical
		float y = rect.origin.y + (self.value + 50) * 0.01 * self.gui.scaleX;
		int controlWidth = 3;
		// constrain pos at edges
		if(y < controlWidth) {
			y = controlWidth;
		}
		// height of slider control & pixel padding
		else if(y > rect.size.height - (controlWidth - 1)) {
			y = rect.size.height - controlWidth - 1;
		}
		else if(self.value == centerValue) {
			controlWidth = 7; // thick line in middle
		}
		CGContextSetLineWidth(context, controlWidth);
		CGContextMoveToPoint(context, round(rect.origin.x), y);
		CGContextAddLineToPoint(context, round(rect.origin.x+rect.size.width-1), y);
		CGContextStrokePath(context);
	}
}

- (void)sendFloat:(float)f {

	if(self.log) {
        f = self.minValue * exp(sizeConvFactor * (double)(f) * 0.01);
    }
	else {
        f = (double)(f) * 0.01 * sizeConvFactor + self.minValue;
	}
	
    if((f < 1.0e-10) && (f > -1.0e-10)) {
        f = 0.0;
	}
	
	[super sendFloat:f];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
		
	double g;
	
	if(isReversed) {
		f = MIN(self.minValue, MAX(self.maxValue, f));
    }
    else {
		f = MIN(self.maxValue, MAX(self.minValue, f));
    }

	if(self.log) {
        g = log(f / self.minValue) / sizeConvFactor;
	}
    else {
        g = (f - self.minValue) / sizeConvFactor;
    }
	[super setValue:(int)(100.0*g + 0.49999)];
	controlPos = self.value;
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
		
		if(self.log) {
			sizeConvFactor = log(self.maxValue / self.minValue) / (double)(size - 1);
		}
		else {
			sizeConvFactor = (self.maxValue - self.minValue) / (double)(size - 1);
		}	
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
			v = MAX(MIN(v, (100 * CGRectGetWidth(self.originalFrame) - 100)), 0);
			controlPos = v;
			[super setValue:v];
		}
		
		[self sendFloat:self.value];
		prevPos = pos.x;
	}
	else if(self.orientation == WidgetOrientationVertical) {
		
		if(!self.steady) {
			int v = (int)(100.0 * (pos.y / self.gui.scaleX));
			v = MAX(MIN(v, (100 * CGRectGetHeight(self.originalFrame) - 100)), 0);
			controlPos = v;
			[super setValue:v];
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
		float delta = pos.x - prevPos;
		float old = self.value;
	
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
		[super setValue:v];
		
		// don't resend old values
		if(old != v) {
			[self sendFloat:v];
		}
		
		prevPos = pos.x;
	}
	else if(self.orientation == WidgetOrientationVertical) {
		float delta = pos.y - prevPos;
		float old = self.value;
	
		int v = 0;
		if(!isOneFinger) {
			controlPos += (int)delta;
		}
		else {
			controlPos += 100 * (int)delta;
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
		[super setValue:v];
		
		// don't resend old values
		if(old != v) {
			[self sendFloat:v];
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
	[self sendFloat:self.value];
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {

	if([message isEqualToString:@"size"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// width, height
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			MIN(MAX([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE), IEM_GUI_MAXSIZE),
			MIN(MAX([[arguments objectAtIndex:1] floatValue], IEM_GUI_MINSIZE), IEM_GUI_MAXSIZE));
		[self checkSize];
		[self reshapeForGui:self.gui];
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
    if(self.value > (size * 100 - 100)) {
        self.value = size * 100 - 100;
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
