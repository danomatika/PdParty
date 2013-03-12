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

@interface VUMeter : IEMWidget

// value is rms in dB
@property (nonatomic, assign) float peakValue; // in dB
@property (nonatomic, assign) BOOL showScale; // show the vu scale?

+ (id)vumeterFromAtomLine:(NSArray *)line withGui:(Gui *)gui;

@end
