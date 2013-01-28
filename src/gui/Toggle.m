/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#import "Toggle.h"

#import "Gui.h"

@implementation Toggle

+ (id)toggleFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	float scaleX = CGRectGetWidth(gui.bounds) / gui.patchWidth;
	float scaleY = CGRectGetHeight(gui.bounds) / gui.patchHeight;

	CGRect frame = CGRectMake(
		[[line objectAtIndex:2] floatValue] * scaleX,
		[[line objectAtIndex:3] floatValue] * scaleY,
		[[line objectAtIndex:5] floatValue] * scaleX,
		[[line objectAtIndex:5] floatValue] * scaleX);

	Toggle *t = [[Toggle alloc] initWithFrame:frame];

	//toggleVal = 1;
	//toggleVal = ofToFloat(atomLine[18]);

	t.init = [[line objectAtIndex:6] integerValue];
	t.sendName = [line objectAtIndex:7];
	t.receiveName = [line objectAtIndex:8];
	t.label.text = [line objectAtIndex:9];
	CGRect labelFrame = CGRectMake(
		[[line objectAtIndex:10] floatValue] * scaleX,
		[[line objectAtIndex:11] floatValue] * scaleY,
		t.label.frame.size.width,
		t.label.frame.size.height
	);
	t.label.frame = labelFrame;
	[t addSubview:t.label];
	
	//setVal(ofToFloat(atomLine[17]), 0);
	//[self setValue:[[line objectAtIndex:17] floatValue]];
	
	//setupReceive();
	//ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
	//initVal();
	
	return t;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if (self) {
        self.fillColor = WIDGET_FILL_COLOR;
        self.frameColor = WIDGET_FRAME_COLOR;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetShouldAntialias(context, NO);
	CGContextTranslateCTM(context, 0.5, 0.5);
    //CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
    
    CGRect frame = rect;
	frame.size = CGSizeMake(CGRectGetWidth(frame), CGRectGetHeight(frame));

    //float pos = ((self.value - self.minimumValue) * frame.size.width) / (self.maximumValue - self.minimumValue);

    // Draw filled region
    //CGRect fillRect = CGRectMake(1.0, 1.0, frame.size.width - 1.0, frame.size.height - 1.0);
    CGContextSetLineWidth(context, 2.0);
	
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 1, 2);
	CGContextAddLineToPoint(context, frame.size.width-2, 2);
    CGContextAddLineToPoint(context, frame.size.width-2, frame.size.height-2);
	CGContextAddLineToPoint(context, 2, frame.size.height-2);
	CGContextAddLineToPoint(context, 2, 1);
    CGContextStrokePath(context);

    //CGContextAddRect(context, fillRect);
    //CGContextFillPath(context);
	
	//CGContextStrokeRect(context, frame);
    
//    CGContextSetLineWidth(context, 6.0);
//    CGContextSetLineCap(context, kCGLineCapRound);
//    
//    
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, pos, frame.origin.y + 4);
//    CGContextAddLineToPoint(context, pos, frame.size.height - 4);
//    CGContextStrokePath(context);
//    
//    CGContextSetLineWidth(context, 2.0);
//    [self drawRoundedRectFrame:context];

	//CGContextRestoreGState(context);
}

- (NSString*) getType {
	return @"Toggle";
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	
//    UITouch *touch = [touches anyObject];
//    CGPoint pos = [touch locationInView:self];
//	
//    [self mapPointToValue:pos];
//    [self setNeedsDisplay]; // TODO: the drawing commands in drawRect don't get erased by this command only
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint pos = [touch locationInView:self];
//	if ([self pointIsWithinBounds:pos]) {
//		[self mapPointToValue:pos];
//	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end

//#include "Gui.h"
//
//namespace gui {
//
//const string Toggle::s_type = "Toggle";
//
//Toggle::Toggle(Gui& parent, const AtomLine& atomLine) : Widget(parent) {
//
//	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
//	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
//	float w = round(ofToFloat(atomLine[5]) / parent.patchWidth * parent.width);
//	float h = round(ofToFloat(atomLine[5]) / parent.patchHeight * parent.height);
//
//	toggleVal = 1;
//	//toggleVal = ofToFloat(atomLine[18]);
//
//	init = ofToInt(atomLine[6]);
//	sendName = atomLine[7];
//	receiveName = atomLine[8];
//	label = atomLine[9];
//	labelPos.x = ofToFloat(atomLine[10]) / parent.patchWidth * parent.width;
//	labelPos.y = ofToFloat(atomLine[11]) / parent.patchHeight * parent.height;
//	
//	setVal(ofToFloat(atomLine[17]), 0);
//	
//	setupReceive();
//	ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
//	initVal();
//	
//	rect.set(x, y, w, h);
//}
//
//void Toggle::draw() {
//	
//	// fill
//	ofFill();
//	ofSetColor(255);
//	ofRect(rect.x, rect.y, rect.width, rect.height);
//	
//	// outline
//	ofNoFill();
//	ofSetColor(0);
//	//ofRect(rect.x, rect.y, rect.width, rect.height);
//	ofLine(rect.x, rect.y, rect.x+1+rect.width, rect.y);
//	ofLine(rect.x, rect.y+1+rect.height, rect.x+1+rect.width, rect.y+1+rect.height);
//	ofLine(rect.x, rect.y, rect.x, rect.y+2+rect.height);
//	ofLine(rect.x+1+rect.width, rect.y, rect.x+1+rect.width, rect.y+1+rect.height);
//		
//	// toggle check
//	if(val != 0) {
//		ofEnableSmoothing();
//		ofLine(rect.x+2, rect.y+2, rect.x-2+rect.width, rect.y-2+rect.height);
//		ofLine(rect.x-2+rect.width, rect.y+2, rect.x+2, rect.y-2+rect.height);
//		ofDisableSmoothing();
//	}
//	
//	drawLabel();
//}
//
//void Toggle::toggle() {
//	if(val == 0)
//		val = toggleVal;
//	else
//		val = 0;
//}
//
//void Toggle::initVal() {
//	if(init != 0)
//		sendFloat(val);
//}
//
//void Toggle::receiveBang(const string& dest) {
//	toggle();
//	sendFloat(val);
//}
//
//void Toggle::receiveFloat(const string& dest, float value) {
//	val = value;
//	sendFloat(val);
//}
//
//void Toggle::receiveList(const string& dest, const pd::List& list) {
//	if(list.len() == 0)
//		return;
//	
//	// pass float through, setting the value
//	if(list.isFloat(0)) {
//		receiveFloat(receiveName, list.asFloat(0));
//	}
//	else if(list.isSymbol(0)) {
//		// if we receive a set message
//		if(list.asSymbol(0) == "set") {
//			// set value but don't pass through
//			if(list.len() > 1 && list.isFloat(1)) {
//				val = list.asFloat(1);
//			}
//		}
//		else if(list.asSymbol(0) == "bang") {
//			// got a bang
//			receiveBang(receiveName);
//		}
//	}
//}
//
//void Toggle::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
//	// set message sets value without sending
//	if(msg == "set" && list.len() > 0 && list.isFloat(0)) {
//		val = list.asFloat(0);
//	}
//}
//
//void Toggle::mousePressed(ofMouseEventArgs &e) {
//	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
//		toggle();
//		sendFloat(val);
//	}
//}
//
//} // namespace
