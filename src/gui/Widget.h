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
#pragma once

#include "ofMain.h"

#include "ofxPd.h"
#include "../Types.h"

namespace gui {

class Gui;

class Widget : public pd::PdReceiver {

	public:
	
		Widget(Gui& parent);
		virtual ~Widget() {}

		virtual void draw() = 0;
		
		virtual void drawLabel();
		
		string setLabel(string& newLabel);
		
		void send(string msg);
		
		void sendFloat(float f);
		
		/// add the receive name and register this widget to
		/// receieve messages from ofxPd
		void setupReceive();
		
		void setVal(float v, float alt);
		
		inline float getVal() {return val;}
		
		virtual void initVal();
		
		/// get the Gui type as a string
		virtual string getType() = 0;
		
		/// PdReceiver callbacks
		virtual void receiveBang(const string& dest);
		virtual void receiveFloat(const string& dest, float value);
		virtual void receiveSymbol(const string& dest, const string& symbol);
		virtual void receiveList(const string& dest, const pd::List& list);
		virtual void receiveMessage(const string& dest, const string& msg, const pd::List& list);
		
		/// input event callbacks
		virtual void mousePressed(ofMouseEventArgs &e);
		
		/// variables
		ofRectangle rect;
		float val;
		int init;
		string sendName, receiveName;
		string label;
		ofVec2f labelPos;
		
	protected:
		
		Gui& parent;
};

} // namespace