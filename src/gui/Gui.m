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

#import "Bang.h"
#import "Toggle.h"
#import "Numberbox.h"
#import "Comment.h"
#import "Canvas.h"
#import "Symbolbox.h"
#import "Radio.h"
#import "Numberbox2.h"
#import "VUMeter.h"

@interface Gui ()

@property (assign, readwrite) int patchWidth;
@property (assign, readwrite) int patchHeight;

@property (assign, readwrite) int fontSize;

@property (assign, readwrite) float scaleX;
@property (assign, readwrite) float scaleY;

@end

@implementation Gui

- (id)init {
	self = [super init];
    if(self) {
		self.widgets = [[NSMutableArray alloc] init];
		self.fontSize = 10;
		self.scaleX = 1.0;
		self.scaleY = 1.0;
    }
    return self;
}

- (void)addComment:(NSArray *)atomLine {
	Comment *c = [Comment commentFromAtomLine:atomLine withGui:self];
	if(c) {
		[self.widgets addObject:c];
		DDLogVerbose(@"Gui: added %@", c.type);
	}
}

- (void)addNumberbox:(NSArray *)atomLine {
	Numberbox *n = [Numberbox numberboxFromAtomLine:atomLine withGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added %@", n.type);
	}
}

- (void)addSymbolbox:(NSArray *)atomLine {
	Symbolbox *s = [Symbolbox symbolboxFromAtomLine:atomLine withGui:self];
	if(s) {
		[self.widgets addObject:s];
		DDLogVerbose(@"Gui: added %@", s.type);
	}
}

- (void)addBang:(NSArray *)atomLine {
	Bang *b = [Bang bangFromAtomLine:atomLine withGui:self];
	if(b) {
		[self.widgets addObject:b];
		DDLogVerbose(@"Gui: added %@", b.type);
	}
}

- (void)addToggle:(NSArray *)atomLine {
	Toggle *t = [Toggle toggleFromAtomLine:atomLine withGui:self];
	if(t) {
		[self.widgets addObject:t];
		DDLogVerbose(@"Gui: added %@", t.type);
	}
}

- (void)addSlider:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation {
	Slider *s = [Slider sliderFromAtomLine:atomLine withOrientation:orientation withGui:self];
	if(s) {
		[self.widgets addObject:s];
		DDLogVerbose(@"Gui: added %@", s.type);
	}
}

- (void)addRadio:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation {
	Radio *r = [Radio radioFromAtomLine:atomLine withOrientation:orientation withGui:self];
	if(r) {
		[self.widgets addObject:r];
		DDLogVerbose(@"Gui: added %@", r.type);
	}
}

- (void)addCanvas:(NSArray *)atomLine {
	Canvas *c = [Canvas canvasFromAtomLine:atomLine withGui:self];
	if(c) {
		[self.widgets addObject:c];
		DDLogVerbose(@"Gui: added %@", c.type);
	}
}

- (void)addNumberbox2:(NSArray *)atomLine {
	Numberbox2 *n = [Numberbox2 numberbox2FromAtomLine:atomLine withGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added %@", n.type);
	}
}

- (void)addVUMeter:(NSArray *)atomLine {
	VUMeter *v = [VUMeter vumeterFromAtomLine:atomLine withGui:self];
	if(v) {
		[self.widgets addObject:v];
		DDLogVerbose(@"Gui: added %@", v.type);
	}
}

- (void)addWidgetsFromAtomLines:(NSArray *)lines {
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
					self.fontSize = [[line objectAtIndex:6] integerValue];
					
					// set pd gui to ios gui scale amount based on relative sizes
					self.scaleX = CGRectGetWidth(self.bounds) / self.patchWidth;
					self.scaleY = CGRectGetHeight(self.bounds) / self.patchHeight;
				}
			}
			else if([lineType isEqualToString:@"restore"]) {
				level -= 1;
			}
			// find different types of UI element in the top level patch
			else if(level == 1) {
				if (line.count >= 2) {
				
					// built in pd things
					if([lineType isEqualToString:@"text"]) {
						[self addComment:line];
					}
					else if([lineType isEqualToString:@"floatatom"]) {
						[self addNumberbox:line];
					}
					else if([lineType isEqualToString:@"symbolatom"]) {
						[self addSymbolbox:line];
					}
					else if([lineType isEqualToString:@"obj"] && line.count >= 5) {
						NSString *objType = [line objectAtIndex:4];
						
						// pd objects
						if([objType isEqualToString:@"bng"]) {
							[self addBang:line];
						}
						else if([objType isEqualToString:@"tgl"]) {
							[self addToggle:line];
						}
						else if([objType isEqualToString:@"hsl"]) {
							[self addSlider:line withOrientation:WidgetOrientationHorizontal];
						}
						else if([objType isEqualToString:@"vsl"]) {
							[self addSlider:line withOrientation:WidgetOrientationVertical];
						}
						else if([objType isEqualToString:@"hradio"]) {
							[self addRadio:line withOrientation:WidgetOrientationHorizontal];
						}
						else if([objType isEqualToString:@"vradio"]) {
							[self addRadio:line withOrientation:WidgetOrientationVertical];
						}
						else if([objType isEqualToString:@"cnv"]) {
							[self addCanvas:line];
						}
						else if([objType isEqualToString:@"nbx"]) {
							[self addNumberbox2:line];
						}
						else if([objType isEqualToString:@"vu"]) {
							[self addVUMeter:line];
						}
						
						// print warnings on objects that aren't completely compatible
						else if([objType isEqualToString:@"keyup"] || [objType isEqualToString:@"keyname"]) {
							DDLogWarn(@"Gui: [keyup] & [keyname] can create, but won't return any events");
						}
					}
				}
			}
		}
	}
}

- (void)addWidgetsFromPatch:(NSString *)patch {
	[self addWidgetsFromAtomLines:[PdParser getAtomLines:[PdParser readPatch:patch]]];
}

- (void)reshapeWidgets {
	for(Widget *widget in self.widgets) {
		[widget reshapeForGui:self];
		[widget setNeedsDisplay]; // redraw to avoid antialiasing on rotate
	}
}

#pragma mark Overridden Getters & Setters

- (void)setBounds:(CGRect)bounds {
	_bounds = bounds;
	self.scaleX = CGRectGetWidth(bounds) / self.patchWidth;
	self.scaleY = CGRectGetHeight(bounds) / self.patchHeight;
}

#pragma Utils

- (NSString *)replaceDollarZeroStringsIn:(NSString *)string fromPatch:(PdFile*)patch {
	if(!string || !patch) {return string;}
	NSMutableString *newString = [NSMutableString stringWithString:string];
	[newString replaceOccurrencesOfString:@"\\$0"
							   withString:[[NSNumber numberWithInt:patch.dollarZero] stringValue]
								  options:NSCaseInsensitiveSearch
									range:NSMakeRange(0, newString.length)];
//	[newString replaceOccurrencesOfString:@"$0"
//							   withString:[[NSNumber numberWithInt:patch.dollarZero] stringValue]
//								  options:NSCaseInsensitiveSearch
//									range:NSMakeRange(0, newString.length)];
	return newString;
}

+ (NSString *)filterEmptyStringValues:(NSString *)atom {
	if(!atom || [atom isEqualToString:@"-"] || [atom isEqualToString:@"empty"]) {
		return @"";
	}
	return atom;
}

@end
