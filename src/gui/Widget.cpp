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
#include "Widget.h"

#include "Gui.h"

namespace gui {

//--------------------------------------------------------------
Widget::Widget(Gui& parent) : parent(parent) {
	val = 0;
	init = 0;
}

void Widget::drawLabel() {
	if(label != "" && label != "empty") {
		parent.font.drawString(label,
			rect.x+labelPos.x, rect.y+labelPos.y+(parent.fontSize/2));
	}
}

string Widget::setLabel(string& newLabel) {
	// drop empty labels
	if(newLabel == "-" || newLabel == "empty")
		return "";
	else
		return newLabel;
}

void Widget::send(string msg) {
	if(sendName != "" && sendName != "empty") {
		parent.pd.sendSymbol(sendName, msg);
	}
}

void Widget::sendFloat(float f) {
	if(sendName != "" && sendName != "empty") {
		parent.pd.sendFloat(sendName, f);
	}
}

void Widget::setupReceive() {
	if(receiveName != "" && receiveName != "empty") {
		parent.pd.subscribe(receiveName);
		parent.pd.addReceiver(*this);
		parent.pd.receive(*this, receiveName);
	}
}

void Widget::setVal(float v, float alt) {
	if(init != 0)
		val = v;
	else
		val = alt;
}
		
void Widget::initVal() {
	if(init != 0) {
		send(ofToString(val));
	}
}

void Widget::receiveBang(const string& dest) {
	ofLogWarning() << getType() << " " << label << " dropped bang";
}

void Widget::receiveFloat(const string& dest, float value) {
	ofLogWarning() << getType() << " " << label << " dropped float";
}

void Widget::receiveSymbol(const string& dest, const string& symbol) {
	ofLogWarning() << getType() << " " << label << " dropped symbol";
}

void Widget::receiveList(const string& dest, const pd::List& list) {
	ofLogWarning() << getType() << " " << label << " dropped list";
}

void Widget::receiveMessage(const string& dest, const string& msg, const pd::List& list) {
	ofLogWarning() << getType() << " "<< label << " dropped message";
}

void Widget::mousePressed(ofMouseEventArgs &e) {
	ofLogWarning() << getType() << " " << label << " dropped mouse pressed";
}

} // namespace
