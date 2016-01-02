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

/// popover wrapper since UIPopoverController is deprecated on iOS 9
@interface Popover : UIViewController

/// view controller to present from (required)
@property (readonly, nonatomic) UIViewController *sourceController;

/// encapsulated content view (required)
@property (readonly, nonatomic) UIView *contentView;

/// used for popover size (default: contentView size)
@property (nonatomic) CGSize contentSize;

/// optional popover background color
@property (nonatomic) UIColor *backgroundColor;

/// inits popover with content view to encapsulate & source controller to present from
- (id)initWithContentView:(UIView *)contentView andSourceController:(UIViewController *)sourceController;

/// presents popover anchored in a specified location in a view
- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;

/// presents in a popover from a given button
- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated;

/// dismiss if presented in a popover
- (void)dismissPopoverAnimated:(BOOL)animated;

/// returns whether the popover is currently visible
- (BOOL)popoverVisible;

@end
