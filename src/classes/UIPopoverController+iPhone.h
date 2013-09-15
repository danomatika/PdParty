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
#import <UIKit/UIKit.h>

// allow UIPopoverController on iPhone
// from http://stackoverflow.com/questions/14787765/uipopovercontroller-for-iphone-not-working
@interface UIPopoverController (iPhonePopover_override)

+ (BOOL)_popoversDisabled;

@end
