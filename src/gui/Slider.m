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

@interface Slider ()

// get scaled value based on width or height & max/min
- (float)horizontalValue:(float)x;
- (float)verticalValue:(float)y;

@end

@implementation Slider

+ (id)sliderFromAtomLine:(NSArray *)line withOrientation:(WidgetOrientation)orientation withGui:(Gui *)gui {

	if(line.count < 23) { // sanity check
		DDLogWarn(@"Slider: Cannot create, atom line length < 23");
		return nil;
	}

	Slider *s = [[Slider alloc] initWithFrame:CGRectZero];
	
	s.sendName = [gui formatAtomString:[line objectAtIndex:11]];
	s.receiveName = [gui formatAtomString:[line objectAtIndex:12]];
	if(![s hasValidSendName] && ![s hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Slider: Dropping, send/receive names are empty");
		return nil;
	}
	
	s.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	
	s.orientation = orientation;
	s.minValue = [[line objectAtIndex:7] floatValue];
	s.maxValue = [[line objectAtIndex:8] floatValue];
	s.log = [[line objectAtIndex:9] integerValue];
	s.inits = [[line objectAtIndex:10] boolValue];
	
	s.label.text = [gui formatAtomString:[line objectAtIndex:13]];
	s.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue], [[line objectAtIndex:15] floatValue]);
	
	s.fillColor = [Gui colorFromIEMColor:[[line objectAtIndex:18] integerValue]];
	s.controlColor = [Gui colorFromIEMColor:[[line objectAtIndex:19] integerValue]];
	s.label.textColor = [Gui colorFromIEMColor:[[line objectAtIndex:20] integerValue]];

	[s reshapeForGui:gui];
	
	if(orientation == WidgetOrientationHorizontal) {
		s.value = ([[line objectAtIndex:21] floatValue] * 0.01 * (s.maxValue - s.minValue)) /
			[[line objectAtIndex:5] floatValue];
	}
	else {
		s.value = ([[line objectAtIndex:21] floatValue] * 0.01 * (s.maxValue - s.minValue)) /
			([[line objectAtIndex:6] floatValue] - 1 + s.minValue);
	}
	
	[s sendInitValue];
	
	return s;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.log = 0;
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
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1));
	
	// slider pos
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	CGContextSetLineWidth(context, 4);
	if(self.orientation == WidgetOrientationHorizontal) {
		float x = round(rect.origin.x + ((self.value - self.minValue) / (self.maxValue - self.minValue)) * rect.size.width);
		// constrain pos at edges
		if(x < 4) { // width of slider control + pixel padding
			x = 4;
		}
		else if(x > rect.size.width - (4 + 1)) {
			x = rect.size.width - 5;
		}
		CGContextMoveToPoint(context, x, round(rect.origin.y));
		CGContextAddLineToPoint(context, x, round(rect.origin.y+rect.size.height-1));
		CGContextStrokePath(context);
	}
	else { // vertical
		float y = round(rect.origin.y+rect.size.height - ((self.value - self.minValue) / (self.maxValue - self.minValue)) * rect.size.height);
		// constrain pos at edges
		if(y < 4) { // width of slider control + pixel padding
			y = 4;
		}
		else if(y > rect.size.height - (4 + 1)) {
			y = rect.size.height - 5;
		}
		CGContextMoveToPoint(context, round(rect.origin.x), y);
		CGContextAddLineToPoint(context, round(rect.origin.x+rect.size.width-1), y);
		CGContextStrokePath(context);
	}
}

- (void)reshapeForGui:(Gui *)gui {
	
	// bounds
	[super reshapeForGui:gui];
	
	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	[self.label sizeToFit];
	int nudgeX = 0, nudgeY = 0;
	if(self.orientation == WidgetOrientationHorizontal) {
		nudgeX = 4;
		nudgeY = -2;
	}
	self.label.frame = CGRectMake(
		round(self.originalLabelPos.x * gui.scaleX) + nudgeX,
		round(self.originalLabelPos.y * gui.scaleY) + nudgeY,
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	[super setValue:MIN(self.maxValue, MAX(self.minValue, f))];
}

- (NSString *)type {
	if(self.orientation == WidgetOrientationHorizontal) {
		return @"HSlider";
	}
	return @"VSlider";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	if(self.orientation == WidgetOrientationHorizontal) {
		self.value = [self horizontalValue:pos.x];
	}
	else {
		self.value = [self verticalValue:pos.y];
	}
	[self sendFloat:self.value];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	if(self.orientation == WidgetOrientationHorizontal) {
		self.value = [self horizontalValue:pos.x];
	}
	else {
		self.value = [self verticalValue:pos.y];
	}
	[self sendFloat:self.value];
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 0) {
		if([Util isNumberIn:list at:0]) {
			[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
		}
		else if([Util isStringIn:list at:0]) {
			if(list.count > 1 && [[list objectAtIndex:0] isEqualToString:@"set"]) {
				if([Util isNumberIn:list at:1]) {
					self.value = [[list objectAtIndex:1] floatValue];
				}
			}
			else if([[list objectAtIndex:0] isEqualToString:@"bang"]) {
				[self receiveBangFromSource:source];
			}
			else {
				[self receiveSymbol:[list objectAtIndex:0] fromSource:source];
			}
		}
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	// set message sets value without sending
	if([message isEqualToString:@"set"] && arguments.count > 0 && [Util isNumberIn:arguments at:0]) {
		self.value = [[arguments objectAtIndex:0] floatValue];
	}
	else if([message isEqualToString:@"bang"]) {
		[self receiveBangFromSource:source];
	}
	else {
		[self receiveList:arguments fromSource:source];
	}
}

#pragma mark Private

- (float)horizontalValue:(float)x {
	return ((x / self.frame.size.width) * (self.maxValue - self.minValue) + self.minValue);
}

- (float)verticalValue:(float)y {
	return (((self.frame.size.height - y) / self.frame.size.height) * (self.maxValue - self.minValue) + self.minValue);
}

@end
