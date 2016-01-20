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
#import "Gui.h"

/// Gui subclass which adds droidparty-specific Widget loading
@interface PartyGui : Gui

#pragma mark Add Widgets

/// droidparty
- (void)addDisplay:(NSArray *)atomLine;
- (void)addNumberbox:(NSArray *)atomLine;
- (void)addRibbon:(NSArray *)atomLine;
- (void)addTaplist:(NSArray *)atomLine;
- (void)addTouch:(NSArray *)atomLine;
- (void)addWordbutton:(NSArray *)atomLine;
- (void)addLoadsave:(NSArray *)atomLine;
- (void)addKnob:(NSArray *)atomLine;
- (void)addMenubang:(NSArray *)atomLine;

@end
