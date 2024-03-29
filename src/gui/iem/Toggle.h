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

@interface Toggle : IEMWidget

/// value when on (default 1), cannot be 0
@property (assign, nonatomic) float nonZeroValue;

- (void)toggle; ///< flip the toggle

@end
