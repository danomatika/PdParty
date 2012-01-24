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
#include "Bang.h"

#include "Gui.h"

namespace gui {

const string Bang::s_type = "Bang";

Bang::Bang(Gui& parent, const AtomLine& atomLine) : Widget(parent) {

	bangVal = false;

	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
	float w = round(ofToFloat(atomLine[5]) / parent.patchWidth * parent.width);
	float h = round(ofToFloat(atomLine[5]) / parent.patchHeight * parent.height);

	sendName = atomLine[9];
	receiveName = atomLine[10];
	label = atomLine[11];
	labelPos.x = ofToFloat(atomLine[12]) / parent.patchWidth * parent.width;
	labelPos.y = ofToFloat(atomLine[13]) / parent.patchHeight * parent.height;
	bangTimeMS = ofToInt(atomLine[6]);
	
	setupReceive();
	ofAddListener(ofEvents.mousePressed, this, &Bang::mousePressed);
	
	rect.set(x, y, w, h);
}

void Bang::draw() {

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
	
	// center circle outline
	ofNoFill();
	ofEnableSmoothing();
	ofEllipse(rect.x+rect.width/2, rect.y+1+rect.height/2, rect.width, rect.height);
	ofDisableSmoothing();
	
	// fill circle is banged
	if(bangVal) {
		bangVal = false;
		timer.setAlarm(bangTimeMS);
	}
	if(!timer.alarm()) {
		ofFill();
		ofEllipse(rect.x+rect.width/2, rect.y+1+rect.height/2, rect.width, rect.height);
	}

	drawLabel();
}

void Bang::bang() {
	bangVal = true;
	parent.pd.sendBang(sendName);
}

void Bang::receiveBang(const string& dest) {
	bang();
}

void Bang::receiveFloat(const string& dest, float value) {
	bang();
}

void Bang::receiveSymbol(const string& dest, const string& symbol) {
	bang();
}

void Bang::receiveList(const string& dest, const pd::List& list) {
	bang();
}

void Bang::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
	bang();
}

void Bang::mousePressed(ofMouseEventArgs &e) {
	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
		bang();
	}
}

} // namespace
