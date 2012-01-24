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

class ofxPd;

namespace gui {

class Gui {

	public:
	
		Gui(ofxPd& pd);
		~Gui() {}
		
		void setSize(int w, int h);
		
		void addComment(const AtomLine& line);
		void addNumberbox(const AtomLine& line);
		
		void addBang(const AtomLine& line);
		void addToggle(const AtomLine& line);
		
		void buildGui(const vector<AtomLine>& atomLines);
		
		void setFont(string file);
		
		void clear();
		
		void draw();
		
		vector<Widget*> widgets;
		int width, height;	///< overall gui draw area size
		int patchWidth, patchHeight;
		
		ofTrueTypeFont font;
		int fontSize;
		string fontFile;
		
		ofxPd& pd;
};

} // namespace
