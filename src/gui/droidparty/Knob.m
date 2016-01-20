/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "Knob.h"

#import "Gui.h"
#include "z_libpd.h"

// from moonlib mknob.c
#define MKNOB_MINSIZE 12

@interface Knob () {
	BOOL isReversed; // is the min value > max value?
	double convFactor; // scaling factor for lin/log value conversion
	UITouch *touch0; // initial touch pointer, nil if none
	CGPoint pos0; // position of initial touch
	float value0; // value of initial touch
	float angle0; // angle of inital touch
}
@property (nonatomic) float controlValue; // normalized value, clockwise 0 -1
@end

@implementation Knob

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 23) { // sanity check
		DDLogWarn(@"Knob: cannot create, atom line length < 23");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		_controlValue = 0;
		isReversed = NO;
		convFactor = 0;
		touch0 = nil;
		pos0 = CGPointZero;
		value0 = 0;
		angle0 = 0;
		self.mouse = 100;
		self.log = NO;
		self.steady = YES;
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
		if(![self hasValidSendName]  && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Knob: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:5] floatValue]);
		
		self.mouse = [[line objectAtIndex:6] floatValue];
		self.minValue = [[line objectAtIndex:7] floatValue];
		self.maxValue = [[line objectAtIndex:8] floatValue];
		self.log = [[line objectAtIndex:9] boolValue];
		self.inits = [[line objectAtIndex:10] boolValue];
		[self checkMinAndMax];
		
		self.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
		self.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue],
										 [[line objectAtIndex:15] floatValue]);
		self.labelFontStyle = [[line objectAtIndex:16] intValue];
		self.labelFontSize = [[line objectAtIndex:17] floatValue];
		
		self.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] intValue]];
		self.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] intValue]];
		self.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] intValue]];
		
		if(self.inits) { // convert saved int to float
			[self initValue:[[line objectAtIndex:21] intValue]];
		}
		self.steady = [[line objectAtIndex:22] boolValue];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	float angle; // clockwise, 0 degrees = down
	if(self.mouse >= 0) {
		angle = self.controlValue * 270 + 45;
	}
	else {
		angle = self.controlValue * 360;
	}

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillEllipseInRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeEllipseInRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
	
	// control
	float littlerad = 0.1f;
	float length = [Util isDeviceATablet] ? 0.9 : 0.85; // slightly smaller on iPhone
	float startX = [self circleX:littlerad angle:(angle-90)];
	float startY = [self circleY:littlerad angle:(angle-90)];
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, startX, startY);
	CGPathAddLineToPoint(path, NULL,
						 ([self circleX:littlerad angle:(angle+90)]),
						 ([self circleY:littlerad angle:(angle+90)]));
	CGPathAddLineToPoint(path, NULL,
						 ([self circleX:length angle:angle]),
						 ([self circleY:length angle:angle]));
	CGPathAddLineToPoint(path, NULL, startX, startY);
	CGContextAddPath(context, path);
	CGContextDrawPath(context, kCGPathFillStroke);
	CGPathRelease(path);
}

// mknob is a dummy in PdParty, so make sure we send the init value manually
- (void)sendInitValue {
	[self sendFloat:self.value];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	double g;
	
	if(isReversed) {
		f = CLAMP(f, self.maxValue, self.minValue);
    }
    else {
		f = CLAMP(f, self.minValue, self.maxValue);
    }
	[super setValue:f];

	if(self.log) { // normalize
        g = log(f / self.minValue) / convFactor;
	}
    else {
        g = (f - self.minValue) / convFactor;
    }
	_controlValue = g;
}

- (void)setControlValue:(float)f {
	_controlValue = f;

	if(self.log) { // denormalize
        f = self.minValue * exp(convFactor * (double)(f));
    }
	else {
        f = (double)(f) * convFactor + self.minValue;
	}
	
    if((f < 1.0e-10) && (f > -1.0e-10)) {
        f = 0.0;
	}
	[super setValue:f];
}

- (void)setLog:(BOOL)l {
	if(_log == l) return;
	_log = l;
	
	if(self.log) {
		[self checkMinAndMax];
	}
	else {
		convFactor = (self.maxValue - self.minValue);
	}
}

- (NSString *)type {
	return @"Knob";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if(touch0) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	touch0 = touch;
	value0 = self.controlValue;
	pos0.x = pos.x;
	pos0.y = pos.y;
	if(self.mouse <= 0) {
		angle0 = [self circularValForX:pos.x andY:pos.y];
		if(!self.steady) {
			self.controlValue = [self boundsForAngle:(angle0)];
		}
	}
	[self sendFloat:self.value];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if([touches containsObject:touch0]) {
		CGPoint pos = [touch0 locationInView:self];
		if(self.mouse > 0) { // vertical/horizontal
			float d, dx = pos.x - pos0.x, dy = pos.y - pos0.y;
			if(fabs(dy) > fabs(dx)) {
				d = -dy;
			}
			else {
				d = dx;
			}
			self.controlValue = CLAMP(value0 + d/self.mouse, 0, 1);
		}
		else { // angular
			float angle = [self circularValForX:pos.x andY:pos.y];
			if(!self.steady) {
				self.controlValue = [self boundsForAngle:(angle)];
			}
			else {
				float dangle = [self fract:(angle - angle0)];
				if(dangle >= 0.5) {
					dangle -= 1;
				}
				if(dangle < -0.5) {
					dangle += 1;
				}
				if(self.mouse == 0) {
					self.controlValue = CLAMP(value0 + dangle, 0, 1);
				}
				else {
					self.controlValue = [self fract:(value0 + dangle)];
				}
				angle0 = angle;
			}
		}
		[self sendFloat:self.value];
		value0 = self.controlValue;
		pos0.x = pos.x;
		pos0.y = pos.y;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if([touches containsObject:touch0]) {
		touch0 = nil;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if([touches containsObject:touch0]) {
		touch0 = nil;
	}
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

	if([message isEqualToString:@"size"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// size, mouse
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			MAX([[arguments objectAtIndex:0] floatValue], MKNOB_MINSIZE),
			MAX([[arguments objectAtIndex:0] floatValue], MKNOB_MINSIZE));
		self.mouse = [[arguments objectAtIndex:1] floatValue];
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

// convert & set saved int init value to float,
// adapted from mknob.c mknob_check_wh()
- (void)initValue:(int)val {

	int H;
    H = self.mouse;
    if(H < 0) {
		H = 360;
	}
    if(H == 0) {
		H = 270;
	}

	double sizeConvFactor, g;
	int size = CGRectGetWidth(self.originalFrame);
	if(self.log) {
		sizeConvFactor = log(self.maxValue/self.minValue) / (H-1);
		g = self.minValue*exp((sizeConvFactor/size)*(double)(val)*0.01);
	}
	else {
		sizeConvFactor = (self.maxValue - self.minValue) / (H-1);
		g = (double)(val)*0.01*(sizeConvFactor + self.minValue);
	}
	if((g < 1.0e-10) && (g > -1.0e-10)) {
		g = 0.0;
	}
	
	self.value = g;
}

// adapted from g_hslider.c & g_vslider.c
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
	
	if(self.log) {
		convFactor = log(self.maxValue / self.minValue);
    }
	else {
        convFactor = (self.maxValue - self.minValue);
	}
}

// returns normalized angle clockwise along the circle ala
// 0.0: bottom
// 0.5: top
// 1.0: bottom again
- (float)circularValForX:(float)x andY:(float)y {
	float angle = DEGREES(atan2f(-y + (CGRectGetHeight(self.frame)/2),
	                             -x + (CGRectGetWidth(self.frame)/2)));
	angle += 90;
	if(angle > 360) {
		angle -= 360;
	}
	if(angle < 0) {
		angle += 360;
	}
	return angle/360;
}

// keep normalized angle within 0-1
- (float)boundsForAngle:(float)angle {
	if(self.mouse == 0) {
		if(angle < 0) {
			return 0;
		}
		else if(angle > 1) {
			return 1;
		}
	}
	angle -= floor(angle);
	return angle;
}

// returns cartesian x position for polar point with frame center as the origin
- (float)circleX:(float)radius angle:(float)angle {
	return CGRectGetWidth(self.frame)/2 + (CGRectGetWidth(self.frame)/2)*radius*cos(RADIANS(angle+90)) - 1;
}

// returns cartesian y position for polar point with frame center as the origin
- (float)circleY:(float)radius angle:(float)angle {
	return CGRectGetHeight(self.frame)/2 + (CGRectGetHeight(self.frame)/2)*radius*sin(RADIANS(angle+90)) - 1;
}

// returns the fractional part of a given number
- (float)fract:(float)f {
	return f - floor(f);
}

@end
