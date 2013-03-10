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
#import "IEMWidget.h"

@class Gui;

@interface Radio : IEMWidget

@property (nonatomic, assign) int width; // pixel width of one side of a cell
@property (nonatomic, assign) int numCells; // number of cells
@property (assign) WidgetOrientation orientation;

+ (id)radioFromAtomLine:(NSArray *)line withOrientation:(WidgetOrientation)orientation withGui:(Gui *)gui;

@end

// a radio cell, do not use directly
@interface RadioCell : UIView

@property (nonatomic, weak) Radio* parent;

@property (nonatomic, assign) int whichCell; // cell id
@property (nonatomic, assign, getter=isSelected) BOOL selected;

@end
