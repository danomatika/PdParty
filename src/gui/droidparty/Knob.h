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
#import "IEMWidget.h"

@class Gui;

// TODO: lin/log not implemented (they aren't in DroidParty either)
@interface Knob : IEMWidget

@property (assign, nonatomic) float mouse;
@property (assign, nonatomic) BOOL log; // linear or logarithmic scale? TODO
@property (assign, nonatomic) BOOL steady; // steady on click?

+ (id)knobFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
