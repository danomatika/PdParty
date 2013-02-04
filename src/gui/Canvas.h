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

@interface Canvas : Widget

@property (assign) int labelFontSize;

+ (id)canvasFromAtomLine:(NSArray*)line withGui:(Gui*)gui;

@end
