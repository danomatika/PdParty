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
#import "Widget.h"

@class Gui;

@interface Numberbox : Widget

@property (nonatomic, assign) int numWidth;
@property (nonatomic, retain) UILabel *numberLabel; // shows the value
@property (nonatomic, retain) NSNumberFormatter *numberLabelFormatter; // formats the value

+ (id)numberboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui;

@end
