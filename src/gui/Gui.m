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
#import "Gui.h"
#import "PdParser.h"

#import "Bang.h"
#import "Toggle.h"
#import "Numberbox.h"
#import "Comment.h"

@implementation Gui

- (id)init {
	self = [super init];
    if(self) {
		self.widgets = [[NSMutableArray alloc] init];
		self.fontSize = 10 * GUI_FONT_SCALE;
		self.scaleX = 1.0;
		self.scaleY = 1.0;
    }
    return self;
}

- (void)addComment:(NSArray*)atomLine {
	Comment *c = [Comment commentFromAtomLine:atomLine withGui:self];
	if(c) {
		[self.widgets addObject:c];
		DDLogVerbose(@"Gui: added Comment");
	}
}

- (void)addNumberbox:(NSArray*)atomLine {
	Numberbox *n = [Numberbox numberboxFromAtomLine:atomLine withGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added Numberbox");
	}
}

- (void)addBang:(NSArray*)atomLine {
	Bang *b = [Bang bangFromAtomLine:atomLine withGui:self];
	if(b) {
		[self.widgets addObject:b];
		DDLogVerbose(@"Gui: added Bang");
	}
}

- (void)addToggle:(NSArray*)atomLine {
	Toggle *t = [Toggle toggleFromAtomLine:atomLine withGui:self];
	if(t) {
		[self.widgets addObject:t];
		DDLogVerbose(@"Gui: added Toggle");
	}
}

- (void)addWidgetsFromAtomLines:(NSArray*)lines {
	int level = 0;
	
	for(NSArray *line in lines) {
		
		if(line.count >= 4) {
		
			NSString *lineType = [line objectAtIndex:1];
			
			// find canvas begin and end line
			if([lineType isEqualToString:@"canvas"]) {
				level++;
				if(level == 1) {
					self.patchWidth = [[line objectAtIndex:4] integerValue];
					self.patchHeight = [[line objectAtIndex:5] integerValue];
					self.fontSize = round([[line objectAtIndex:6] integerValue] * GUI_FONT_SCALE);
					
					// set pd gui to ios gui scale amount based on relative sizes
					self.scaleX = CGRectGetWidth(self.bounds) / self.patchWidth;
					self.scaleY = CGRectGetHeight(self.bounds) / self.patchHeight;
				}
			}
			else if([lineType isEqualToString:@"restore"]) {
				level -= 1;
			}
			else if(level == 1) {
			
				NSString *objType = [line objectAtIndex:4];
			
				// built in pd things
				if([lineType isEqualToString:@"text"]) {
					[self addComment:line];
				}
				else if([lineType isEqualToString:@"floatatom"]) {
					[self addNumberbox:line];
				}
				else if([lineType isEqualToString:@"obj"] && line.count >= 5) {
					// pd objects
					if([objType isEqualToString:@"bng"])
						[self addBang:line];
					else if([objType isEqualToString:@"tgl"])
						[self addToggle:line];
				}
			}
		}
	}
}

- (void)addWidgetsFromPatch:(NSString*)patch {
	[self addWidgetsFromAtomLines:[PdParser getAtomLines:[PdParser readPatch:patch]]];
}

@end

//#include "Comment.h"
//#include "Numberbox.h"
//#include "Bang.h"
//#include "Toggle.h"
//
//namespace gui {
//
////--------------------------------------------------------------
//Gui::Gui(ofxPd& pd) : pd(pd) {
//	width = 0;
//	height = 0;
//	patchWidth = 0;
//	patchHeight = 0;
//	
//	fontSize = 10;
//	fontFile = "";
//}
//
//void Gui::setSize(int w, int h) {
//	width = w;
//	height = h;
//}
//
//void Gui::addComment(const AtomLine& line) {
//	Comment* c = new Comment(*this, line);
//	widgets.push_back(c);
//	cout << "Gui: added Comment \"" << c->label << "\"" << endl;
//}
//
//void Gui::addNumberbox(const AtomLine& line) {
//	Numberbox* nb = new Numberbox(*this, line);
//	widgets.push_back(nb);
//	cout << "Gui: added Numberbox \"" << nb->label << "\"" << endl;
//}
//
//void Gui::addBang(const AtomLine& line) {
//	Bang* b = new Bang(*this, line);
//	widgets.push_back(b);
//	cout << "Gui: added Bang \"" << b->label << "\"" << endl;
//}
//
//void Gui::addToggle(const AtomLine& line) {
//	Toggle* t = new Toggle(*this, line);
//	widgets.push_back(t);
//	cout << "Gui: added Toggle \"" << t->label << "\"" << endl;
//}
//
//void Gui::buildGui(const vector<AtomLine>& atomLines) {
//
//	int level = 0;
//	
//	for(int i = 0; i < atomLines.size(); ++i) {
//		
//		const AtomLine& line = atomLines[i];
//		
//		if(line.size() >= 4) {
//		
//			// find canvas begin and end line
//			if(line[1] == "canvas") {
//				level++;
//				if(level == 1) {
//					patchWidth = ofToInt(line[4]);
//					patchHeight = ofToInt(line[5]);
//					fontSize = ofToInt(line[6]);
//					font.loadFont(ofToDataPath(fontFile), fontSize);
//				}
//			}
//			else if(line[1] == "restore") {
//				level -= 1;
//			}
//			else if(level == 1) {
//			
//				// built in pd things
//				if(line[1] == "text") {
//					addComment(line);
//				}
//				else if(line[1] == "floatatom") {
//					addNumberbox(line);
//				}
//				else if(line[1] == "obj" && line.size() >= 5) {
//					// pd objects
//					if(atomLines[i][4] == "bng")
//						addBang(line);
//					else if(atomLines[i][4] == "tgl")
//						addToggle(line);
//				}
//			}
//		}
//	}
//}
//
//void Gui::setFont(string file) {
//	fontFile = file;
//}
//
//void Gui::clear() {
//	for(int i = 0; i < widgets.size(); ++i)
//		delete widgets[i];
//	widgets.clear();
//}
//
//void Gui::draw() {
//	for(int i = 0; i < widgets.size(); ++i)
//		widgets[i]->draw();
//}
//		
//} // namespace
