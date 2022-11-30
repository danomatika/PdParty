/*
 * Copyright (c) 2022 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

/// pd patch view
@interface PatchView : UIView

/// if set, forward patch canvas and widget touch events to a touch responder
@property (weak, nonatomic) UIResponder *touchResponder;

/// force a rotation of the view in degrees, ie. 0, -90, 90, 180
@property (assign, nonatomic) int rotation;

@end
