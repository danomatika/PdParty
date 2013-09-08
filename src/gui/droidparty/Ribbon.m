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
#import "Ribbon.h"

#import "Gui.h"

@interface Ribbon () {
	BOOL touchDown;
	double sizeConvFactor; // scaling factor for lin/log value conversion
	int leftControlPos, rightControlPos;
	float prevLeftControlPos, prevRightControlPos;
}
- (void)sendValues;
- (void)checkSize;
- (BOOL)checkControlsAtPoint:(CGPoint)pos;
@end

@implementation Ribbon

+ (id)ribbonFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 7) { // sanity check
		DDLogWarn(@"Ribbon: cannot create, atom line length < 7");
		return nil;
	}

	Ribbon *r = [[Ribbon alloc] initWithFrame:CGRectZero];

	r.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	if(![r hasValidSendName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Ribbon: dropping, send name is empty");
		return nil;
	}
	
	r.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	[r checkSize];
	
	r.gui = gui;
	
	return r;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.label = nil; // don't need label
		touchDown = NO;
		prevLeftControlPos = 0;
		prevRightControlPos = 0;
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
	
	// border
	if(touchDown) {
		CGContextSetLineWidth(context, 2.0);
	}
	else {
		CGContextSetLineWidth(context, 1.0);
	}
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
	
	// control
	
	float x = (self.value + 50) * 0.01 * self.gui.scaleX;
	int controlWidth = 3;
	// constrain pos at edges
	if(x < controlWidth) {
		x = controlWidth;
	}
	// width of slider control & pixel padding
	else if(x > rect.size.width - (controlWidth - 1)) {
		x = rect.size.width - controlWidth - 1;
	}
	CGContextSetLineWidth(context, controlWidth);
	CGContextMoveToPoint(context, x, round(rect.origin.y));
	CGContextAddLineToPoint(context, x, round(rect.origin.y+rect.size.height-1));
	CGContextStrokePath(context);

	
	
//	int leftEdge = 3 * self.gui.scaleX, rightEdge = CGRectGetWidth(self.frame) - leftEdge;
//	CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
////	CGContextFillRect(context, CGRectMake(
////		MAX(MIN(round(self.value2 * CGRectGetWidth(self.frame)), rightEdge), leftEdge), 1,
////		MAX(MIN((round(self.value - self.value2) * CGRectGetWidth(self.frame)), rightEdge), leftEdge), CGRectGetHeight(self.frame) - 1));
//
//	CGContextFillRect(context, CGRectMake(
//		MAX(MIN(round(self.value * CGRectGetWidth(self.frame)), rightEdge), leftEdge), 1,
//		leftEdge, CGRectGetHeight(self.frame) - 1));
		
//	CGContextFillRect(context, CGRectMake(
//		MAX(MIN(round(self.value2 * CGRectGetWidth(self.frame)), rightEdge), leftEdge), 1,
//		leftEdge, CGRectGetHeight(self.frame) - 1));
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];
	sizeConvFactor = 1 / (CGRectGetWidth(self.originalFrame) - 1);

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	//CGSize charSize = [@"0" sizeWithFont:self.label.font]; // assumes monspaced font
	self.label.preferredMaxLayoutWidth = round(CGRectGetWidth(self.frame) * 0.75);
	[self.label sizeToFit];
	self.label.center = CGPointMake(round(CGRectGetWidth(self.frame)/2), round(CGRectGetHeight(self.frame)/2));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
		
	double g;
	
	f = MIN(1.0, MAX(0.0, f));
	g = f / sizeConvFactor;

	[super setValue:(int)(100.0*g + 0.49999)];
	rightControlPos = self.value;
}

- (void)setValue2:(float)f {

	double g;
	
	f = MIN(1.0, MAX(0.0, f));
	g = f / sizeConvFactor;

	_value2 = (int)(100.0*g + 0.49999);
	leftControlPos = self.value2;
	
	[self setNeedsDisplay];
}

- (NSString *)type {
	return @"Ribbon";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//touchDown = YES;
	
	UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
NSLog(@"touch down %f %f", pos.x, pos.y);
//	if([self checkControlsAtPoint:pos]) {
//		[self sendList:[NSArray arrayWithObjects:
//			[NSNumber numberWithFloat:self.value],
//			[NSNumber numberWithFloat:self.value2], nil]];
//	}
	
	int controlWidth = 10 * self.gui.scaleX;
	
//	if(pos.x >= rightControlPos && pos.x <= rightControlPos + controlWidth) {
	
//		int v = (int)(100.0 * (pos.x / self.gui.scaleX));
//		v = MAX(MIN(v, (100 * CGRectGetWidth(self.originalFrame) - 100)), 0);
//		prevRightPos = v;
//		[super setValue:v];

		[self sendValues];
		prevRightControlPos = pos.x;
//	}

//	if(pos.x >= leftControlPos && pos.x <= leftControlPos + controlWidth) {
//		[self sendValues];
//		prevLeftControlPos = pos.x;
//	}
	//[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];

//	if([self checkControlsAtPoint:pos]) {
//		[self sendList:[NSArray arrayWithObjects:
//			[NSNumber numberWithFloat:self.value],
//			[NSNumber numberWithFloat:self.value2], nil]];
//	}


	int controlWidth = 10 * self.gui.scaleX;
	
//	if(pos.x >= rightControlPos - controlWidth && pos.x <= rightControlPos) {
	
		float delta = (pos.x - prevRightControlPos) / self.gui.scaleX;
		float old = self.value;
	
	
		int v = 0;
		rightControlPos += (int)delta;
		v = rightControlPos;
		
		if(v > (100 * CGRectGetWidth(self.originalFrame) - 100)) {
			v = 100 * CGRectGetWidth(self.originalFrame) - 100;
			rightControlPos += 50;
			rightControlPos -= rightControlPos % 100;
		}
		if(v < 0) {
			v = 0;
			rightControlPos -= 50;
			rightControlPos -= rightControlPos % 100;
		}
		[super setValue:v];
		
		// don't resend old values
		if(old != v) {
			[self sendValues];
		}
		
		prevRightControlPos = pos.x;
	
	
	NSLog(@"moved: value is %f", self.value);
	
	
	
//		int v = (int)(100.0 * (pos.x / self.gui.scaleX));
//		v = MAX(MIN(v, (100 * CGRectGetWidth(self.originalFrame) - 100)), 0);
//		prevRightPos = v;
//		[super setValue:v];
	
//		[self sendList:[NSArray arrayWithObjects:
//			[NSNumber numberWithFloat:self.value],
//			[NSNumber numberWithFloat:self.value2], nil]];
//		prevRightPos = pos.x;


//	}

//	if(pos.x >= leftControlPos && pos.x <= leftControlPos + controlWidth) {
//
//		float delta = (pos.x - prevLeftControlPos) / self.gui.scaleX;
//		float old = self.value2;
//	
//		int v = 0;
//		leftControlPos += (int)delta;
//		v = leftControlPos;
//		
//		if(v > (100 * CGRectGetWidth(self.originalFrame) - 100)) {
//			v = 100 * CGRectGetWidth(self.originalFrame) - 100;
//			leftControlPos += 50;
//			leftControlPos -= leftControlPos % 100;
//		}
//		if(v < 0) {
//			v = 0;
//			leftControlPos -= 50;
//			leftControlPos -= leftControlPos % 100;
//		}
//		_value2 = v;
//		[self setNeedsDisplay];
//		
//		// don't resend old values
//		if(old != v) {
//			[self sendValues];
//		}
//		
//		prevLeftControlPos = pos.x;
//	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//[self sendBang];
	touchDown = NO;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self setNeedsDisplay];
}

#pragma mark Private

- (void)sendValues {

	float v1 = self.value;
	v1 = (double)(v1) * 0.01 * sizeConvFactor;
    if((v1 < 1.0e-10) && (v1 > -1.0e-10)) {
        v1 = 0.0;
	}
	
	float v2 = self.value2;
	v2 = (double)(v2) * 0.01 * sizeConvFactor;
    if((v2 < 1.0e-10) && (v2 > -1.0e-10)) {
        v2 = 0.0;
	}

	[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:v1],
		[NSNumber numberWithFloat:v2], nil]];
}

- (void)checkSize {

	float size = CGRectGetWidth(self.originalFrame);

    if(size < 2) {
        size = 2;
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			size, CGRectGetHeight(self.originalFrame));
	}
	
    if(self.value > (size * 100 - 100)) {
        self.value = size * 100 - 100;
    }

	sizeConvFactor = 1 / (double)(size - 1);
}

- (BOOL)checkControlsAtPoint:(CGPoint)pos {
	
	float controlWidth = 10 * self.gui.scaleX;
	
	float rightCtlPos = self.value * CGRectGetWidth(self.frame);
	if(pos.x >= rightCtlPos - controlWidth && pos.x <= rightCtlPos) {
		touchDown = YES;
		//self.value = pos.x / CGRectGetWidth(self.frame);
		
		return YES;
	}
	
	float leftCtlPos = self.value2 * CGRectGetWidth(self.frame);
	if(pos.x >= leftCtlPos && pos.x <= leftCtlPos + controlWidth) {
		touchDown = YES;
		//self.value2 = pos.x / CGRectGetWidth(self.frame);
		return YES;
	}
	
	return NO;
}

@end
