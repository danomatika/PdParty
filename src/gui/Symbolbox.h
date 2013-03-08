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

@interface Symbolbox : Widget

@property (strong)	NSString *symbol; // symbol text
@property (nonatomic, assign) int symWidth;
@property (assign) int labelPos; // LRUD positioning

@property (strong) UILabel *symbolLabel; // shows the symbol

+ (id)symbolboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui;

@end
