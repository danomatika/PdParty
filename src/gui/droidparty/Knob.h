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

// moonlib [mknob] implementation
@interface Knob : IEMWidget

// mouse excursion (default: 100)
// >0: vert/horz sensitivity, higher numbers are less sensitive
//  0: angular rotation with min/max stops
// -1: full angular rotation without stops
@property (assign, nonatomic) float mouse;

@property (assign, nonatomic) BOOL log; // linear or logarithmic scale?
@property (assign, nonatomic) BOOL steady; // steady on click?

@end
