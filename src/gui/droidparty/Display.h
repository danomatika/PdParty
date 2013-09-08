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

@interface Display : Widget

// TODO: this works but dosen't handle line wrapping etc
@property (weak, nonatomic) Gui *gui;

+ (id)displayFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
