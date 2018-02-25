/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

@class Popover;

/// grid of menu buttons, some generated from MenuBang objects
/// adds rounded rect background if number of buttons exceeds available width
/// to indicate menu horizontal scroll
@interface MenuViewController : UICollectionViewController

/// containing popover
@property (weak, nonatomic) Popover *popover;

/// width & height for a single cell
@property (assign, nonatomic) int cellSize;

/// row height including padding
@property (readonly, nonatomic) int height;

/// use a light background?
@property (assign, nonatomic) BOOL lightBackground;

/// the current background color
@property (readonly, nonatomic) UIColor *backgroundColor;

/// how many buttons are shown by default: restart, speaker?, console?, etc
@property (readonly, nonatomic) int numDefaultButtons;

#pragma Layout

/// align edges to superview
- (void)alignToSuperview;

/// align edges to superview sides & bottom
- (void)alignToSuperviewBottom;

/// align edges to superview sides & top
- (void)alignToSuperviewTop;

@end
