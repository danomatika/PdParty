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
#import "Numberbox.h"

#import "Gui.h"

@implementation Numberbox

@synthesize numWidth;

+ (id)numberboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	int numWidth = [[line objectAtIndex:4] integerValue];

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round(numWidth * 15 * gui.scaleX),
		round(15 * gui.scaleX));

	Numberbox *n = [[Numberbox alloc] initWithFrame:frame];

	n.minValue = [[line objectAtIndex:5] floatValue];
	n.maxValue = [[line objectAtIndex:6] floatValue];
	n.numWidth = numWidth;
	n.sendName = [line objectAtIndex:10];
	n.receiveName = [line objectAtIndex:9];
	n.label.text = [line objectAtIndex:8];
//	CGRect labelFrame = CGRectMake(
//		round([[line objectAtIndex:12] floatValue] * scaleX),
//		round([[line objectAtIndex:13] floatValue] * scaleY),
//		n.label.frame.size.width,
//		n.label.frame.size.height
//	);
//	n.label.frame = labelFrame;
	[n addSubview:n.label];
	
//	// calc screen bounds for the numbers that can fit
//	numWidth = ofToInt(atomLine[4]);
//	string tmp;
//	for(int i = 0; i < numWidth; ++i) {
//		tmp += "#";
//	}
//	rect = parent.font.getStringBoundingBox(tmp, x, y);
//	rect.x -= 3;
//	rect.y += 3;
//	rect.width += 3-parent.font.getSize();
//	rect.height += 3;
//
//	// set the label pos from the LRUD setting
//	label = atomLine[8];
//	int pos = ofToInt(atomLine[7]);
//	switch(pos) {
//		default: // 0 LEFT
//			labelPos.x = rect.x - parent.font.getSize()*(label.size()-1)-1;
//			labelPos.y = y;
//			break;
//		case 1: // RIGHT
//			labelPos.x = rect.x+rect.width+1;
//			labelPos.y = y;
//			break;
//		case 2: // TOP
//			labelPos.x = x-4;
//			labelPos.y = rect.y-2-parent.font.getLineHeight()/2;
//			break;
//		case 3: // BOTTOM
//			labelPos.x = x-4;
//			labelPos.y = rect.y+rect.height+2+parent.font.getLineHeight()/2;
//			break;
//	}
//
//	setVal(0, 0);
	
	//setupReceive();
	//ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
	
	return n;
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
	CGContextAddLineToPoint(context, frame.size.width-6, 0);
    CGContextAddLineToPoint(context, frame.size.width-1, 6);
	CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, 0);
    CGContextStrokePath(context);
}

- (NSString*) getType {
	return @"Numberbox";
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
//const string Numberbox::s_type = "Numberbox";
//
//Numberbox::Numberbox(Gui& parent, const AtomLine& atomLine) : Widget(parent) {
//
//	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
//	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
//	
//	min = ofToFloat(atomLine[5]);
//	max = ofToFloat(atomLine[6]);
//	sendName = atomLine[10];
//	receiveName = atomLine[9];
//	
//	// calc screen bounds for the numbers that can fit
//	numWidth = ofToInt(atomLine[4]);
//	string tmp;
//	for(int i = 0; i < numWidth; ++i) {
//		tmp += "#";
//	}
//	rect = parent.font.getStringBoundingBox(tmp, x, y);
//	rect.x -= 3;
//	rect.y += 3;
//	rect.width += 3-parent.font.getSize();
//	rect.height += 3;
//
//	// set the label pos from the LRUD setting
//	label = atomLine[8];
//	int pos = ofToInt(atomLine[7]);
//	switch(pos) {
//		default: // 0 LEFT
//			labelPos.x = rect.x - parent.font.getSize()*(label.size()-1)-1;
//			labelPos.y = y;
//			break;
//		case 1: // RIGHT
//			labelPos.x = rect.x+rect.width+1;
//			labelPos.y = y;
//			break;
//		case 2: // TOP
//			labelPos.x = x-4;
//			labelPos.y = rect.y-2-parent.font.getLineHeight()/2;
//			break;
//		case 3: // BOTTOM
//			labelPos.x = x-4;
//			labelPos.y = rect.y+rect.height+2+parent.font.getLineHeight()/2;
//			break;
//	}
//	
//	setVal(0, 0);
//	
//	setupReceive();
//	//ofAddListener(ofEvents.mousePressed, this, &Numberbox::mousePressed);
//
//}
//
//void Numberbox::draw() {
//
//	// outline
//	ofSetColor(0);
//	ofLine(rect.x, rect.y, rect.x-5+rect.width, rect.y);
//	ofLine(rect.x, rect.y+rect.height, rect.x+rect.width, rect.y+rect.height);
//	ofLine(rect.x, rect.y, rect.x, rect.y+1+rect.height);
//	ofLine(rect.x+rect.width, rect.y+5, rect.x+rect.width, rect.y+rect.height);
//	ofLine(rect.x-5+rect.width, rect.y, rect.x+rect.width, rect.y+5);
//
//	parent.font.drawString(ofToString(val), rect.x+3, rect.y+2+parent.fontSize);
//
//	drawLabel();
//}
//
//void Numberbox::drawLabel() {
//	if(label != "" && label != "empty") {
//		parent.font.drawString(label,
//			labelPos.x, labelPos.y+(parent.fontSize/2));
//	}
//}
//
//void Numberbox::receiveFloat(const string& dest, float value) {
//	if(min != 0 || max != 0)
//		val = std::min(max, std::max(value, min));
//	else
//		val = value;
//	sendFloat(val);
//}
//
//void Numberbox::receiveList(const string& dest, const pd::List& list) {
//	if(list.len() > 0 && list.isFloat(0))
//		receiveFloat(receiveName, list.asFloat(0));
//}
//
//void Numberbox::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
//	// set message sets value without sending
//	if(msg == "set" && list.len() > 0 && list.isFloat(0)) {
//		val = list.asFloat(0);
//	}
//}
//
//void Numberbox::mousePressed(ofMouseEventArgs &e) {
////	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
////	}
//}
//
//} // namespace
