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

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Cannot create Toggle, atom line length < 18");
		return nil;
	}

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX));

	Toggle *t = [[Toggle alloc] initWithFrame:frame];

	t.inits = [[line objectAtIndex:6] boolValue];
	t.sendName = [gui formatAtomString:[line objectAtIndex:7]];
	t.receiveName = [gui formatAtomString:[line objectAtIndex:8]];
	if(![t hasValidSendName] && ![t hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Dropping Toggle, send/receive names are empty");
		return nil;
	}
	
	t.label.text = [gui formatAtomString:[line objectAtIndex:9]];
	if(![t.label.text isEqualToString:@""]) {
		t.label.font = [UIFont systemFontOfSize:gui.fontSize];
		[t.label sizeToFit];
		CGRect labelFrame = CGRectMake(
			round([[line objectAtIndex:10] floatValue] * gui.scaleX),
			round(([[line objectAtIndex:11] floatValue] * gui.scaleY) - gui.fontSize),
			t.label.frame.size.width,
			t.label.frame.size.height
		);
		t.label.frame = labelFrame;
		[t addSubview:t.label];
	}
	
	t.toggleValue = [[line objectAtIndex:18] floatValue];
	t.value = [[line objectAtIndex:17] floatValue];
	
	[t sendInitValue];
	
	return t;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if (self) {
		self.toggleValue = 1;
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
	
	// toggle
	if(self.value != 0) {
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, 2, 2);
		CGContextAddLineToPoint(context, frame.size.width-3, frame.size.height-3);
		CGContextStrokePath(context);
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, frame.size.width-3, 2);
		CGContextAddLineToPoint(context, 2, frame.size.height-3);
		CGContextStrokePath(context);
	}
}

- (void)toggle {
	if(self.value == 0) {
		self.value = self.toggleValue;
	}
	else {
		self.value = 0;
	}
}

#pragma mark Overridden Getters & Setters

- (void)setValue:(float)f {
	if(f != 0) { // remember enabled value
		self.toggleValue = f;
	}
	[super setValue:f];
}

- (NSString*)type {
	return @"Toggle";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggle];
	[self sendFloat:self.value];
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	[self toggle];
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	
	if(list.count == 0) {
		return;
	}
	
	// pass float through, setting the value
	if([Util isNumberIn:list at:0]) {
		[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
	}
	else if([Util isStringIn:list at:0]) {
		// if we receive a set message
		if([[list objectAtIndex:0] isEqualToString:@"set"]) {
			// set value but don't pass through
			if(list.count > 1 && [Util isNumberIn:list at:1]) {
				self.value = [[list objectAtIndex:1] floatValue];
			}
		}
		else if([[list objectAtIndex:0] isEqualToString:@"bang"]) {
			// got a bang
			[self receiveBangFromSource:source];
		}
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	// set message sets value without sending
	if([message isEqualToString:@"set"] && arguments.count > 0 && [Util isNumberIn:arguments at:0]) {
		self.value = [[arguments objectAtIndex:0] floatValue];
	}
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
