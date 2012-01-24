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

class Comment : public Widget {

	public:

		Comment(Gui& parent, const AtomLine& atomLine);

		void draw();
		
		inline string getType() {return s_type;}
		
	private:
		
		static const string s_type;
};

} // namespace