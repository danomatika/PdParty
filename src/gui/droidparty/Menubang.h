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
#import "Browser.h"

@class Gui;

@interface Menubang : Widget

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSString *imagePath;

+ (id)menubangFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

// currently loaded menu bangs
+ (NSArray *)menubangs;

@end
