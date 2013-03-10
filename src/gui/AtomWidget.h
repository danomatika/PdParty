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

// a pd atom gui baseclass
@interface AtomWidget : Widget

@property (assign) int labelPos; // LRUD positioning

@property (assign, nonatomic) int valueWidth; // number of value chars to show
@property (strong) UILabel *valueLabel; // shows the value

@end
