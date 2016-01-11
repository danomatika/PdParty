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

@interface Taplist : Widget

@property (strong, nonatomic) NSMutableArray *list;

// set list receive name, essentially self.receiveName + "-list"
@property (readonly, strong, nonatomic) NSString *listReceiveName;
@property (weak, nonatomic) Gui *gui; // gui pointer needed for edit message reshapes

+ (id)taplistFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

- (void)reshapeLabel:(Gui *)gui;

@end
