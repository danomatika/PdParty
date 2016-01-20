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

@interface Bang : IEMWidget

/// how long to wait before showing a new flash
@property (assign, nonatomic) int interruptTimeMS;

/// how long to show flash
@property (assign, nonatomic) int holdTimeMS;

@end
