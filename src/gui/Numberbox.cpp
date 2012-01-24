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
#include "Numberbox.h"

#include "Gui.h"

namespace gui {

const string Numberbox::s_type = "Numberbox";

Numberbox::Numberbox(Gui& parent, const AtomLine& atomLine) : Widget(parent) {

	float x = round(ofToFloat(atomLine[2]) / parent.patchWidth * parent.width);
	float y = round(ofToFloat(atomLine[3]) / parent.patchHeight * parent.height);
	
	min = ofToFloat(atomLine[5]);
	max = ofToFloat(atomLine[6]);
	sendName = atomLine[10];
	receiveName = atomLine[9];
	
	// calc screen bounds for the numbers that can fit
	numWidth = ofToInt(atomLine[4]);
	string tmp;
	for(int i = 0; i < numWidth; ++i) {
		tmp += "#";
	}
	rect = parent.font.getStringBoundingBox(tmp, x, y);
	rect.x -= 3;
	rect.y += 3;
	rect.width += 3-parent.font.getSize();
	rect.height += 3;

	// set the label pos from the LRUD setting
	label = atomLine[8];
	int pos = ofToInt(atomLine[7]);
	switch(pos) {
		default: // 0 LEFT
			labelPos.x = rect.x - parent.font.getSize()*(label.size()-1)-1;
			labelPos.y = y;
			break;
		case 1: // RIGHT
			labelPos.x = rect.x+rect.width+1;
			labelPos.y = y;
			break;
		case 2: // TOP
			labelPos.x = x-4;
			labelPos.y = rect.y-2-parent.font.getLineHeight()/2;
			break;
		case 3: // BOTTOM
			labelPos.x = x-4;
			labelPos.y = rect.y+rect.height+2+parent.font.getLineHeight()/2;
			break;
	}
	
	setVal(0, 0);
	
	setupReceive();
	//ofAddListener(ofEvents.mousePressed, this, &Numberbox::mousePressed);

}

void Numberbox::draw() {

	// outline
	ofSetColor(0);
	ofLine(rect.x, rect.y, rect.x-5+rect.width, rect.y);
	ofLine(rect.x, rect.y+rect.height, rect.x+rect.width, rect.y+rect.height);
	ofLine(rect.x, rect.y, rect.x, rect.y+1+rect.height);
	ofLine(rect.x+rect.width, rect.y+5, rect.x+rect.width, rect.y+rect.height);
	ofLine(rect.x-5+rect.width, rect.y, rect.x+rect.width, rect.y+5);

	parent.font.drawString(ofToString(val), rect.x+3, rect.y+2+parent.fontSize);

	drawLabel();
}

void Numberbox::drawLabel() {
	if(label != "" && label != "empty") {
		parent.font.drawString(label,
			labelPos.x, labelPos.y+(parent.fontSize/2));
	}
}

void Numberbox::receiveFloat(const string& dest, float value) {
	if(min != 0 || max != 0)
		val = std::min(max, std::max(value, min));
	else
		val = value;
	sendFloat(val);
}

void Numberbox::receiveList(const string& dest, const pd::List& list) {
	if(list.len() > 0 && list.isFloat(0))
		receiveFloat(receiveName, list.asFloat(0));
}

void Numberbox::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
	// set message sets value without sending
	if(msg == "set" && list.len() > 0 && list.isFloat(0)) {
		val = list.asFloat(0);
	}
}

void Numberbox::mousePressed(ofMouseEventArgs &e) {
//	if(e.button == OF_MOUSE_LEFT && rect.inside(e.x, e.y)) {
//	}
}

} // namespace
