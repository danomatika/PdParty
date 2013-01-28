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
#import "Widget.h"
#import "../Log.h"

@interface Widget () {}
@end

@implementation Widget

@synthesize value;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.fillColor = WIDGET_FILL_COLOR;
        self.frameColor = WIDGET_FRAME_COLOR;
		self.backgroundColor = [UIColor clearColor];
		
		self.minValue = 0.0;
        self.maxValue = 1.0;
	
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = WIDGET_FRAME_COLOR;
		label.textAlignment = UITextAlignmentLeft;
    }
    return self;
}

#pragma mark - Public 

- (void) addValueTarget:(id)target action:(SEL)action {
	self.valueTarget = target;
	self.valueAction = action;
}

#pragma mark -
#pragma mark Overridden getters / setters

- (void)setValue:(float)f {
    value = f;
    if (self.valueTarget) {
        [self.valueTarget performSelector:self.valueAction withObject:self];
    }
    [self setNeedsDisplay];
}

- (NSString*) getType {
	return @"Widget";
}

#pragma mark - PdListener

- (void)receiveBangFromSource:(NSString *)source {
	DDLogInfo(@"%@ dropped bang", [self getType]);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogInfo(@"%@ dropped float", [self getType]);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogInfo(@"%@ dropped symbol", [self getType]);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	DDLogInfo(@"%@ dropped list", [self getType]);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	DDLogInfo(@"%@ dropped message", [self getType]);
}

@end

//#include "Gui.h"
//
//namespace gui {
//
////--------------------------------------------------------------
//Widget::Widget(Gui& parent) : parent(parent) {
//	val = 0;
//	init = 0;
//}
//
//void Widget::drawLabel() {
//	if(label != "" && label != "empty") {
//		parent.font.drawString(label,
//			rect.x+labelPos.x, rect.y+labelPos.y+(parent.fontSize/2));
//	}
//}
//
//string Widget::setLabel(string& newLabel) {
//	// drop empty labels
//	if(newLabel == "-" || newLabel == "empty")
//		return "";
//	else
//		return newLabel;
//}
//
//void Widget::send(string msg) {
//	if(sendName != "" && sendName != "empty") {
//		parent.pd.sendSymbol(sendName, msg);
//	}
//}
//
//void Widget::sendFloat(float f) {
//	if(sendName != "" && sendName != "empty") {
//		parent.pd.sendFloat(sendName, f);
//	}
//}
//
//void Widget::setupReceive() {
//	if(receiveName != "" && receiveName != "empty") {
//		parent.pd.subscribe(receiveName);
//		parent.pd.addReceiver(*this);
//		parent.pd.receive(*this, receiveName);
//	}
//}
//
//void Widget::setVal(float v, float alt) {
//	if(init != 0)
//		val = v;
//	else
//		val = alt;
//}
//		
//void Widget::initVal() {
//	if(init != 0) {
//		send(ofToString(val));
//	}
//}
//
//void Widget::receiveBang(const string& dest) {
//	ofLogWarning() << getType() << " " << label << " dropped bang";
//}
//
//void Widget::receiveFloat(const string& dest, float value) {
//	ofLogWarning() << getType() << " " << label << " dropped float";
//}
//
//void Widget::receiveSymbol(const string& dest, const string& symbol) {
//	ofLogWarning() << getType() << " " << label << " dropped symbol";
//}
//
//void Widget::receiveList(const string& dest, const pd::List& list) {
//	ofLogWarning() << getType() << " " << label << " dropped list";
//}
//
//void Widget::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
//	ofLogWarning() << getType() << " "<< label << " dropped message";
//}
//
//void Widget::mousePressed(ofMouseEventArgs &e) {
//	ofLogWarning() << getType() << " " << label << " dropped mouse pressed";
//}
//
//} // namespace
