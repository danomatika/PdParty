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

@interface Radio : IEMWidget

@property (assign, nonatomic) WidgetOrientation orientation; ///< (default horz)
@property (assign, nonatomic) int size; ///< pixel size of one side of a cell
@property (assign, nonatomic) int numCells; ///< number of cells (default 8)

@end
