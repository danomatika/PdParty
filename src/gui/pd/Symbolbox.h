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
#import "AtomWidget.h"

@class Gui;

@interface Symbolbox : AtomWidget

@property (strong, nonatomic)	NSString *symbol; // symbol text access

+ (id)symbolboxFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
