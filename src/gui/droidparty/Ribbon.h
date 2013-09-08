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
#import "Widget.h"

@class Gui;

// TODO: this isn't done/working yet
@interface Ribbon : Widget

@property (weak, nonatomic) Gui *gui;

//   value2          value
// [   ||||||||||||||||   ]
//
// value: right control
@property (assign, nonatomic) float value2; // left control

+ (id)ribbonFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
