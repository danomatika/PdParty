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

#import "Log.h"
#import "PdDispatcher.h"

// suppress leak as we should be fine in ARC
// from http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
#define SuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)

@interface Widget () {}
@property (nonatomic, assign) SEL valueAction;
@property (nonatomic, assign) id valueTarget;
@end

@implementation Widget

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
		self.fillColor = WIDGET_FILL_COLOR;
        self.frameColor = WIDGET_FRAME_COLOR;
		self.backgroundColor = [UIColor clearColor];
		
		self.minValue = 0.0;
        self.maxValue = 1.0;
		self.value = 0.0;
		self.init = 0;
	
		self.sendName = @"";
		self.receiveName = @"";
	
		self.label = [[UILabel alloc] initWithFrame:CGRectZero];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.textColor = WIDGET_FRAME_COLOR;
		self.label.textAlignment = UITextAlignmentLeft;
		
		self.valueTarget = nil;
		self.valueAction = nil;
	}
    return self;
}

- (void)dealloc {
	if([self hasValidReceiveName]) {
		[dispatcher removeListener:self forSource:self.receiveName];
	}
}

- (void)addValueTarget:(id)target action:(SEL)action {
	self.valueTarget = target;
	self.valueAction = action;
}

- (BOOL)hasValidSendName {
	return (self.sendName && ![self.sendName isEqualToString:@""]);
}

- (BOOL)hasValidReceiveName {
	return (self.receiveName && ![self.receiveName isEqualToString:@""]);
}

#pragma mark Sending

- (void)send:(NSString*)message {
	if([self hasValidSendName]) {
		[PdBase sendSymbol:message toReceiver:self.sendName];
	}
}

- (void)sendFloat:(float)f {
	if([self hasValidSendName]) {
		[PdBase sendFloat:f toReceiver:self.sendName];
	}
}

- (void)sendInitValue {
	if(self.init != 0) {
		[self sendFloat:self.value];
	}
}

#pragma mark Overridden Getters & Setters

- (void)setValue:(float)f {
	_value = f;
    if(self.valueTarget) {
        SuppressPerformSelectorLeakWarning(
			[self.valueTarget performSelector:self.valueAction withObject:self]
		);
    }
    [self setNeedsDisplay];
}

- (void)setReceiveName:(NSString *)name {
	if(![name isEqualToString:@""]) {
		[dispatcher removeListener:self forSource:self.receiveName]; // remove old name
		_receiveName = name;
		[dispatcher addListener:self forSource:self.receiveName]; // add new one		
	}
}

- (NSString*)type {
	return @"Widget";
}

#pragma mark Static Dispatcher

static PdDispatcher *dispatcher = nil;

+ (PdDispatcher*)dispatcher {
  return dispatcher;
}

+ (void)setDispatcher:(PdDispatcher*)d {
	dispatcher = d;
}

#pragma Static Utils

+ (NSString *)filterEmptyStringValues:(NSString*)atom {
	if(!atom || [atom isEqualToString:@"-"] || [atom isEqualToString:@"empty"]) {
		return @"";
	}
	return atom;
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped bang", self.type);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped float", self.type);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped symbol", self.type);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped list", self.type);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped message", self.type);
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
