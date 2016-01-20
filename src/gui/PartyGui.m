/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PartyGui.h"

// droidparty
#import "Display.h"
#import "Numberbox.h"
#import "Ribbon.h"
#import "Taplist.h"
#import "Touch.h"
#import "Wordbutton.h"
#import "Loadsave.h"
#import "Knob.h"
#import "Menubang.h"

@implementation PartyGui

#pragma mark Add Widgets

- (void)addDisplay:(NSArray *)atomLine {
	Display *d = [[Display alloc] initWithAtomLine:atomLine andGui:self];
	if(d) {
		[self.widgets addObject:d];
		DDLogVerbose(@"Gui: added %@", d.type);
	}
}

- (void)addNumberbox:(NSArray *)atomLine {
	Numberbox *n = [[Numberbox alloc] initWithAtomLine:atomLine andGui:self];
	if(n) {
		[self.widgets addObject:n];
		DDLogVerbose(@"Gui: added %@", n.type);
	}
}

- (void)addRibbon:(NSArray *)atomLine {
	Ribbon *r = [[Ribbon alloc] initWithAtomLine:atomLine andGui:self];
	if(r) {
		[self.widgets addObject:r];
		DDLogVerbose(@"Gui: added %@", r.type);
	}
}

- (void)addTaplist:(NSArray *)atomLine {
	Taplist *t = [[Taplist alloc] initWithAtomLine:atomLine andGui:self];
	if(t) {
		[self.widgets addObject:t];
		DDLogVerbose(@"Gui: added %@", t.type);
	}
}

- (void)addTouch:(NSArray *)atomLine {
	Touch *t = [[Touch alloc] initWithAtomLine:atomLine andGui:self];
	if(t) {
		[self.widgets addObject:t];
		DDLogVerbose(@"Gui: added %@", t.type);
	}
}

- (void)addWordbutton:(NSArray *)atomLine {
	Wordbutton *w = [[Wordbutton alloc] initWithAtomLine:atomLine andGui:self];
	if(w) {
		[self.widgets addObject:w];
		DDLogVerbose(@"Gui: added %@", w.type);
	}
}

- (void)addLoadsave:(NSArray *)atomLine {
	Loadsave *l = [[Loadsave alloc] initWithAtomLine:atomLine andGui:self];
	if(l) {
		[self.widgets addObject:l];
		DDLogVerbose(@"Gui: added %@", l.type);
	}
}

- (void)addKnob:(NSArray *)atomLine {
	Knob *k = [[Knob alloc] initWithAtomLine:atomLine andGui:self];
	if(k) {
		[self.widgets addObject:k];
		DDLogVerbose(@"Gui: added %@", k.type);
	}
}

- (void)addMenubang:(NSArray *)atomLine {
	Menubang *m = [[Menubang alloc] initWithAtomLine:atomLine andGui:self];
	if(m) {
		[self.widgets addObject:m];
		DDLogVerbose(@"Gui: added %@", m.type);
	}
}

#pragma mark Gui

// droidparty objects
- (BOOL)addObjectType:(NSString *)type fromAtomLine:(NSArray *)atomLine {
	if([type isEqualToString:@"display"]) {
		[self addDisplay:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"numberbox"]) {
		[self addNumberbox:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"ribbon"]) {
		[self addRibbon:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"taplist"]) {
		[self addTaplist:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"touch"]) {
		[self addTouch:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"wordbutton"]) {
		[self addWordbutton:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"loadsave"]) {
		[self addLoadsave:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"mknob"]) {
		[self addKnob:atomLine];
		return YES;
	}
	else if([type isEqualToString:@"menubang"]) {
		[self addMenubang:atomLine];
		return YES;
	}
	return [super addObjectType:type fromAtomLine:atomLine];
}

@end