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

@interface Numberbox2 : IEMWidget

@property (assign, nonatomic) BOOL log; // linear or logarithmic scale?
@property (assign, nonatomic) BOOL steady; // steady on click?
@property (assign, nonatomic) float logHeight;

@property (assign, nonatomic) int valueWidth; // number of value chars to show
@property (strong, nonatomic) UILabel *valueLabel; // shows the value

+ (id)numberbox2FromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
