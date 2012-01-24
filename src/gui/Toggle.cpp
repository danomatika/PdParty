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
#include "Toggle.h"

#include "Gui.h"

namespace gui {

const string Toggle::s_type = "Toggle";

Toggle::Toggle(Gui& parent, const AtomLine& atomLine) : Widget(parent) {

	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
	float w = round(ofToFloat(atomLine[5]) / parent.patchWidth * parent.width);
	float h = round(ofToFloat(atomLine[5]) / parent.patchHeight * parent.height);

	toggleVal = 1;
	//toggleVal = ofToFloat(atomLine[18]);

	init = ofToInt(atomLine[6]);
	sendName = atomLine[7];
	receiveName = atomLine[8];
	label = atomLine[9];
	labelPos.x = ofToFloat(atomLine[10]) / parent.patchWidth * parent.width;
	labelPos.y = ofToFloat(atomLine[11]) / parent.patchHeight * parent.height;
	
	setVal(ofToFloat(atomLine[17]), 0);
	
	setupReceive();
	ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
	initVal();
	
	rect.set(x, y, w, h);
}

void Toggle::draw() {
	
	// fill
	ofFill();
	ofSetColor(255);
	ofRect(rect.x, rect.y, rect.width, rect.height);
	
	// outline
	ofNoFill();
	ofSetColor(0);
	//ofRect(rect.x, rect.y, rect.width, rect.height);
	ofLine(rect.x, rect.y, rect.x+1+rect.width, rect.y);
	ofLine(rect.x, rect.y+1+rect.height, rect.x+1+rect.width, rect.y+1+rect.height);
	ofLine(rect.x, rect.y, rect.x, rect.y+2+rect.height);
	ofLine(rect.x+1+rect.width, rect.y, rect.x+1+rect.width, rect.y+1+rect.height);
		
	// toggle check
	if(val != 0) {
		ofEnableSmoothing();
		ofLine(rect.x+2, rect.y+2, rect.x-2+rect.width, rect.y-2+rect.height);
		ofLine(rect.x-2+rect.width, rect.y+2, rect.x+2, rect.y-2+rect.height);
		ofDisableSmoothing();
	}
	
	drawLabel();
}

void Toggle::toggle() {
	if(val == 0)
		val = toggleVal;
	else
		val = 0;
}

void Toggle::initVal() {
	if(init != 0)
		sendFloat(val);
}

void Toggle::receiveBang(const string& dest) {
	toggle();
	sendFloat(val);
}

void Toggle::receiveFloat(const string& dest, float value) {
	val = value;
	sendFloat(val);
}

void Toggle::receiveList(const string& dest, const pd::List& list) {
	if(list.len() == 0)
		return;
	
	// pass float through, setting the value
	if(list.isFloat(0)) {
		receiveFloat(receiveName, list.asFloat(0));
	}
	else if(list.isSymbol(0)) {
		// if we receive a set message
		if(list.asSymbol(0) == "set") {
			// set value but don't pass through
			if(list.len() > 1 && list.isFloat(1)) {
				val = list.asFloat(1);
			}
		}
		else if(list.asSymbol(0) == "bang") {
			// got a bang
			receiveBang(receiveName);
		}
	}
}

void Toggle::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
	// set message sets value without sending
	if(msg == "set" && list.len() > 0 && list.isFloat(0)) {
		val = list.asFloat(0);
	}
}

void Toggle::mousePressed(ofMouseEventArgs &e) {
	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
		toggle();
		sendFloat(val);
	}
}

} // namespace
