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
#include "Comment.h"

#include "Gui.h"

namespace gui {

const string Comment::s_type = "Comment";

Comment::Comment(Gui& parent, const AtomLine& atomLine) : Widget(parent) {

	// create the comment string
	ostringstream text;
	for(int i = 4; i < atomLine.size(); ++i) {
		text << atomLine[i];
		if(i < atomLine.size() - 1) {
			text << " ";
		}
	}

	label = text.str();
	labelPos.x = ofToFloat(atomLine[2]) / parent.patchWidth * parent.width;
	labelPos.y = ofToFloat(atomLine[3]) / parent.patchHeight * parent.height + parent.fontSize;
}

void Comment::draw() {
	drawLabel();
}

} // namespace
