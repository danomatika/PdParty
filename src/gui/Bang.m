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
#import "Bang.h"

#import "Gui.h"

@implementation Bang

@synthesize bangTimeMS;

+ (id)bangFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX));

	Bang *b = [[Bang alloc] initWithFrame:frame];

	b.sendName = [line objectAtIndex:9];
	b.receiveName = [line objectAtIndex:10];
	b.label.text = [line objectAtIndex:11];
	CGRect labelFrame = CGRectMake(
		round([[line objectAtIndex:12] floatValue] * gui.scaleX),
		round([[line objectAtIndex:13] floatValue] * gui.scaleY),
		b.label.frame.size.width,
		b.label.frame.size.height
	);
	b.label.frame = labelFrame;
	[b addSubview:b.label];
	
	b.bangTimeMS = [[line objectAtIndex:6] integerValue];
	
	//setupReceive();
	//ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
	
	return b;
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
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextSetLineWidth(context, 1.0);
	
    CGRect frame = rect;
	
	// border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, frame.size.width-1, 0);
    CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, 0);
    CGContextStrokePath(context);

	// bang
	CGRect circleFrame = CGRectMake(1, 1, frame.size.width-3, frame.size.height-3);
	CGContextStrokeEllipseInRect(context, circleFrame);
}

- (NSString*) getType {
	return @"Bang";
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
//const string Bang::s_type = "Bang";
//
//Bang::Bang(Gui& parent, const AtomLine& atomLine) : Widget(parent) {
//
//	bangVal = false;
//
//	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
//	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
//	float w = round(ofToFloat(atomLine[5]) / parent.patchWidth * parent.width);
//	float h = round(ofToFloat(atomLine[5]) / parent.patchHeight * parent.height);
//
//	sendName = atomLine[9];
//	receiveName = atomLine[10];
//	label = atomLine[11];
//	labelPos.x = ofToFloat(atomLine[12]) / parent.patchWidth * parent.width;
//	labelPos.y = ofToFloat(atomLine[13]) / parent.patchHeight * parent.height;
//	bangTimeMS = ofToInt(atomLine[6]);
//	
//	setupReceive();
//	ofAddListener(ofEvents.mousePressed, this, &Bang::mousePressed);
//	
//	rect.set(x, y, w, h);
//}
//
//void Bang::draw() {
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
//	// center circle outline
//	ofNoFill();
//	ofEnableSmoothing();
//	ofEllipse(rect.x+rect.width/2, rect.y+1+rect.height/2, rect.width, rect.height);
//	ofDisableSmoothing();
//	
//	// fill circle is banged
//	if(bangVal) {
//		bangVal = false;
//		timer.setAlarm(bangTimeMS);
//	}
//	if(!timer.alarm()) {
//		ofFill();
//		ofEllipse(rect.x+rect.width/2, rect.y+1+rect.height/2, rect.width, rect.height);
//	}
//
//	drawLabel();
//}
//
//void Bang::bang() {
//	bangVal = true;
//	parent.pd.sendBang(sendName);
//}
//
//void Bang::receiveBang(const string& dest) {
//	bang();
//}
//
//void Bang::receiveFloat(const string& dest, float value) {
//	bang();
//}
//
//void Bang::receiveSymbol(const string& dest, const string& symbol) {
//	bang();
//}
//
//void Bang::receiveList(const string& dest, const pd::List& list) {
//	bang();
//}
//
//void Bang::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
//	bang();
//}
//
//void Bang::mousePressed(ofMouseEventArgs &e) {
//	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
//		bang();
//	}
//}
//
//} // namespace
