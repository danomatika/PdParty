/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "Gui.h"

#import "PdParser.h"
#import "PdFile.h"

// pd
#import "Number.h"
#import "Symbol.h"
#import "Comment.h"

// iem
#import "Bang.h"
#import "Toggle.h"
#import "Number2.h"
#import "Slider.h"
#import "Radio.h"
#import "VUMeter.h"
#import "Canvas.h"

@interface Gui ()

@property (assign, readwrite) int patchWidth;
@property (assign, readwrite) int patchHeight;

@property (assign, readwrite) int fontSize;

@property (assign, readwrite) float scaleX;
@property (assign, readwrite) float scaleY;

// add other objects and print warnings for non-compatible objects
- (void)addObject:(NSArray *)atomLine atLevel:(int)level;

@end

@implementation Gui

- (id)init {
	self = [super init];
    if(self) {
		self.widgets = [[NSMutableArray alloc] init];
		self.fontName = nil; // sets default font
		self.fontSize = 10;
		self.scaleX = 1.0;
		self.scaleY = 1.0;
    }
    return self;
}

#pragma mark Add Widgets

- (void)addNumber:(NSArray *)atomLine {
	Number *n = [[Number alloc] initWithAtomLine:atomLine andGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added %@", n.type);
	}
}

- (void)addSymbol:(NSArray *)atomLine {
	Symbol *s = [[Symbol alloc] initWithAtomLine:atomLine andGui:self];
	if(s) {
		[self.widgets addObject:s];
		DDLogVerbose(@"Gui: added %@", s.type);
	}
}

- (void)addComment:(NSArray *)atomLine {
	Comment *c = [[Comment alloc] initWithAtomLine:atomLine andGui:self];
	if(c) {
		[self.widgets addObject:c];
		DDLogVerbose(@"Gui: added %@", c.type);
	}
}

- (void)addBang:(NSArray *)atomLine {
	Bang *b = [[Bang alloc] initWithAtomLine:atomLine andGui:self];
	if(b) {
		[self.widgets addObject:b];
		DDLogVerbose(@"Gui: added %@", b.type);
	}
}

- (void)addToggle:(NSArray *)atomLine {
	Toggle *t = [[Toggle alloc] initWithAtomLine:atomLine andGui:self];
	if(t) {
		[self.widgets addObject:t];
		DDLogVerbose(@"Gui: added %@", t.type);
	}
}

- (void)addNumber2:(NSArray *)atomLine {
	Number2 *n = [[Number2 alloc] initWithAtomLine:atomLine andGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added %@", n.type);
	}
}

- (void)addSlider:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation {
	Slider *s = [[Slider alloc] initWithAtomLine:atomLine andGui:self];
	if(s) {
		s.orientation = orientation;
		[self.widgets addObject:s];
		DDLogVerbose(@"Gui: added %@", s.type);
	}
}

- (void)addRadio:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation {
	Radio *r = [[Radio alloc] initWithAtomLine:atomLine andGui:self];
	if(r) {
		r.orientation = orientation;
		[self.widgets addObject:r];
		DDLogVerbose(@"Gui: added %@", r.type);
	}
}

- (void)addVUMeter:(NSArray *)atomLine {
	VUMeter *v = [[VUMeter alloc] initWithAtomLine:atomLine andGui:self];
	if(v) {
		[self.widgets addObject:v];
		DDLogVerbose(@"Gui: added %@", v.type);
	}
}

- (void)addCanvas:(NSArray *)atomLine {
	Canvas *c = [[Canvas alloc] initWithAtomLine:atomLine andGui:self];
	if(c) {
		[self.widgets addObject:c];
		DDLogVerbose(@"Gui: added %@", c.type);
	}
}

// iem gui objects
- (BOOL)addObjectType:(NSString *)type fromAtomLine:(NSArray *)atomLine atLevel:(int)level {
	if(level != 1) {return NO;} // ignore sub patches
	if([type isEqualToString:@"bng"]) {
		[self addBang:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"tgl"]) {
		[self addToggle:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"nbx"]) {
		[self addNumber2:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"hsl"]) {
		[self addSlider:atomLine withOrientation:WidgetOrientationHorizontal];
		return YES;
	}
	else if([type isEqualToString:@"vsl"]) {
		[self addSlider:atomLine withOrientation:WidgetOrientationVertical];
		return YES;
	}
	else if([type isEqualToString:@"hradio"]) {
		[self addRadio:atomLine withOrientation:WidgetOrientationHorizontal];
		return YES;
	}
	else if([type isEqualToString:@"vradio"]) {
		[self addRadio:atomLine withOrientation:WidgetOrientationVertical];
		return YES;
	}
	else if([type isEqualToString:@"vu"]) {
		[self addVUMeter:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"cnv"]) {
		[self addCanvas:atomLine];
		return YES;
	}
	return NO;
}

- (void)addWidgetsFromAtomLines:(NSArray *)lines {
	int level = 0;
	for(NSArray *line in lines) {
		if(line.count >= 4) {
			NSString *lineType = line[1];
			
			// find canvas begin and end line
			if([lineType isEqualToString:@"canvas"]) {
				level++;
				if(level == 1) {
					self.patchWidth = [line[4] intValue];
					self.patchHeight = [line[5] intValue];
					self.fontSize = [line[6] intValue];
					
					// check for bad canvas sizes
					if(self.patchWidth < 20 || self.patchHeight < 20) {
						self.patchWidth = self.parentViewSize.width;
						self.patchHeight = self.parentViewSize.height;
						DDLogWarn(@"Gui: patch size < 20x20, using screen size with scaling of 1.0");
					}
					else {
						// set pd gui to ios gui scale amount based on relative sizes
						self.scaleX = self.parentViewSize.width / self.patchWidth;
						self.scaleY = self.parentViewSize.height / self.patchHeight;
					}
					
					// sanity check
					if(self.scaleX <= 0) {self.scaleX = 1.0;}
					if(self.scaleY <= 0) {self.scaleY = 1.0;}
				}
			}
			else if([lineType isEqualToString:@"restore"]) {
				level -= 1;
			}
			// find different types of UI elements in the top level patch
			else if(level == 1) {
				if(line.count >= 2) {
				
					// built in pd things
					if([lineType isEqualToString:@"floatatom"]) {
						[self addNumber:line];
					}
					else if([lineType isEqualToString:@"symbolatom"]) {
						[self addSymbol:line];
					}
					else if([lineType isEqualToString:@"text"]) {
						[self addComment:line];
					}
					else if([lineType isEqualToString:@"obj"] && line.count >= 5) {
						// iem GUIs and other objects
						[self addObject:line atLevel:level];
					}
				}
			}
			// find non-UI elements in sub patches
			else {
				if(line.count >= 2) {
					if([lineType isEqualToString:@"obj"] && line.count >= 5) {
						[self addObject:line atLevel:level];
					}
				}
			}
		}
	}
}

- (void)addWidgetsFromPatch:(NSString *)patch {
	[self addWidgetsFromAtomLines:[PdParser getAtomLines:[PdParser readPatch:patch]]];
}

#pragma mark Manipulate Widgets

- (void)initWidgetsFromPatch:(PdFile *)patch {
	for(Widget *widget in self.widgets) {
		[widget replaceDollarZerosForGui:self fromPatch:patch];
	}
}

- (void)initWidgetsFromPatch:(PdFile *)patch andAddToView:(UIView *)view {
	for(Widget *widget in self.widgets) {
		[widget replaceDollarZerosForGui:self fromPatch:patch];
		[view addSubview:widget];
		[widget setup];
	}
}

- (void)reshapeWidgets {
	for(Widget *widget in self.widgets) {
		[widget reshape];
		[widget setNeedsDisplay]; // redraw to avoid antialiasing on rotate
	}
}

- (void)removeWidgetsFromSuperview {
	for(Widget *widget in self.widgets) {
		[widget removeFromSuperview];
	}
}

- (void)removeAllWidgets {
	for(Widget *widget in self.widgets) {
		[widget cleanup];
	}
	[self.widgets removeAllObjects];
}

#pragma mark Utils

- (NSString *)replaceDollarZeroStringsIn:(NSString *)string fromPatch:(PdFile *)patch {
	if(!string || !patch) {return string;}
	NSMutableString *newString = [NSMutableString stringWithString:string];
	[newString replaceOccurrencesOfString:@"\\$0"
							   withString:[[NSNumber numberWithInt:patch.dollarZero] stringValue]
								  options:NSCaseInsensitiveSearch
									range:NSMakeRange(0, newString.length)];
	[newString replaceOccurrencesOfString:@"#0"
							   withString:[[NSNumber numberWithInt:patch.dollarZero] stringValue]
								  options:NSCaseInsensitiveSearch
									range:NSMakeRange(0, newString.length)];
	return newString;
}

+ (NSString *)filterEmptyStringValues:(NSString *)atom {
	if(!atom || [atom isEqualToString:@"-"] || [atom isEqualToString:@"empty"]) {
		return @"";
	}
	return atom;
}

#pragma mark Overridden Getters & Setters

- (void)setParentViewSize:(CGSize)parentViewSize {
	_parentViewSize = parentViewSize;
	self.scaleX = self.parentViewSize.width / self.patchWidth;
	self.scaleY = self.parentViewSize.height / self.patchHeight;
}

- (void)setFontName:(NSString *)fontName {
	_fontName = fontName == nil ? GUI_FONT_NAME : fontName;
}

#pragma mark Private

// add other objects
- (void)addObject:(NSArray *)atomLine atLevel:(int)level {
	NSString *objType = atomLine[4];

	// look for additional built in objects
	BOOL added = [self addObjectType:objType fromAtomLine:atomLine atLevel:level];

	// print warnings on objects that aren't completely compatible
	if(!added && ([objType isEqualToString:@"keyup"] || [objType isEqualToString:@"keyname"])) {
		DDLogWarn(@"Gui: [keyup] & [keyname] can create, but won't return any events");
	}
}

@end
