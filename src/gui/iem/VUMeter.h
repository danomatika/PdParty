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

/// self.value is rms in dB
@interface VUMeter : IEMWidget

@property (assign, nonatomic) float peakValue; ///< in dB
@property (assign, nonatomic) BOOL showScale; ///< show the vu scale?

@end
