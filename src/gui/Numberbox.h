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

@interface Numberbox : Widget

@property (assign, nonatomic) int numWidth;
@property (assign) int labelPos; // LRUD positioning

@property (strong) UILabel *numberLabel; // shows the value
@property (strong) NSNumberFormatter *numberLabelFormatter; // formats the value

+ (id)numberboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui;

@end
