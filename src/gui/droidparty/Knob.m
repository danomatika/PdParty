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
#include "g_all_guis.h" // iem gui

@interface Knob () {
	UITouch *touch0; // initial touch pointer, nil if none
	CGPoint pos0; // position of initial touch
	float value0; // value of initial touch
	float angle0; // angle of inital touch
}
@end

@implementation Knob

+ (id)knobFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 23) { // sanity check
		DDLogWarn(@"Knob: cannot create, atom line length < 23");
		return nil;
	}

	Knob *k = [[Knob alloc] initWithFrame:CGRectZero];
	
	k.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
	k.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
	if(![k hasValidSendName]  && ![k hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Knob: dropping, send/receive names are empty");
		return nil;
	}
	
	k.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:5] floatValue]);
	
	k.mouse = [[line objectAtIndex:6] floatValue];
	k.minValue = [[line objectAtIndex:7] floatValue];
	k.maxValue = [[line objectAtIndex:8] floatValue];
	k.log = [[line objectAtIndex:9] boolValue];
	k.inits = [[line objectAtIndex:10] boolValue];
	
	k.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
	k.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue],
	                                 [[line objectAtIndex:15] floatValue]);
	k.labelFontStyle = [[line objectAtIndex:16] intValue];
	k.labelFontSize = [[line objectAtIndex:17] floatValue];
	
	k.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] intValue]];
	k.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] intValue]];
	k.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] intValue]];
	
	k.value = [[line objectAtIndex:21] floatValue];
	
	if([line count] > 21 && [line isNumberAt:22]) {
		k.steady = ![[line objectAtIndex:22] boolValue];
	}
	
	return k;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.log = NO;
		self.steady = YES;
		touch0 = nil;
		pos0 = CGPointZero;
		value0 = 0;
		angle0 = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

	float angle; // clockwise, 0 degrees = down
	if(self.mouse >= 0) {
		angle = self.value * 270 + 45;
	}
	else {
		angle = self.value * 360;
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
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL,
						 [self circleX:littlerad angle:(angle-90)],
						 [self circleY:littlerad angle:(angle-90)]);
	CGPathAddLineToPoint(path, NULL,
						 [self circleX:littlerad angle:(angle+90)],
						 [self circleY:littlerad angle:(angle+90)]);
	CGPathAddLineToPoint(path, NULL,
						 [self circleX:0.9 angle:angle],
						 [self circleY:0.9 angle:angle]);
	CGPathAddLineToPoint(path, NULL,
						 [self circleX:littlerad angle:(angle-90)],
						 [self circleY:littlerad angle:(angle-90)]);
	CGContextAddPath(context, path);
	CGContextDrawPath(context, kCGPathFillStroke);
	CGPathRelease(path);
}

- (void)sendValue {
	[super sendFloat:((self.maxValue-self.minValue) * self.value + self.minValue)];
}

#pragma mark Overridden Getters / Setters

//- (void)setValue:(float)f {
//	f = CLAMP(f, self.minValue, self.maxValue);
//	[super setValue:(f - self.minValue) / (self.maxValue-self.minValue)]; // normalize to 0-1
//}

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
	value0 = self.value;
	pos0.x = pos.x;
	pos0.y = pos.y;
	if(self.mouse <= 0) {
		angle0 = [self circularValForX:pos.x andY:pos.y];
		if(!self.steady) {
			self.value = [self boundsForAngle:(angle0)];
		}
	}
	[self sendValue];
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
			self.value = CLAMP(value0 + d/self.mouse, 0, 1);
		}
		else { // angular
			float angle = [self circularValForX:pos.x andY:pos.y];
			if(!self.steady) {
				self.value = [self boundsForAngle:(angle)];
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
					self.value = CLAMP(value0 + dangle, 0, 1);
				}
				else {
					self.value = [self fract:(value0 + dangle)];
				}
				angle0 = angle;
			}
		}
		[self sendValue];
		value0 = self.value;
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
	[self sendValue];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendValue];
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
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		self.mouse = [[arguments objectAtIndex:1] floatValue];
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
	return CGRectGetWidth(self.frame)/2 + CGRectGetWidth(self.frame)/2*radius*cos(RADIANS(angle+90));
}

// returns cartesian y position for polar point with frame center as the origin
- (float)circleY:(float)radius angle:(float)angle {
	return CGRectGetHeight(self.frame)/2 + CGRectGetHeight(self.frame)/2*radius*sin(RADIANS(angle+90));
}

// returns the fractional part of a given number
- (float)fract:(float)f {
	return f - floor(f);
}

@end
