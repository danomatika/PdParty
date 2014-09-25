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

@interface Loadsave : Widget

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *directory;
@property (strong, nonatomic) NSString *ext;

+ (id)loadsaveFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
