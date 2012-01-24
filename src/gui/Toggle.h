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

#include "Widget.h"

namespace gui {

class Toggle : public Widget {

	public:

		Toggle(Gui& parent, const AtomLine& atomLine);

		void draw();

		void toggle();
		
		void initVal();
		
		inline string getType() {return s_type;}
		
		/// PdReceiver callbacks
		void receiveBang(const string& dest);
		void receiveFloat(const string& dest, float value);
		void receiveList(const string& dest, const pd::List& list);
		void receiveMessage(const string& dest, const string& msg, const pd::List& list);
		
		/// input event callbacks
		void mousePressed(ofMouseEventArgs &e);
		
		/// variables
		float toggleVal;
		
	private:
	
		static const string s_type;
};

} // namespace