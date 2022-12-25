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

@class ControlsView;

/// control events
@protocol ControlsViewDelegate <NSObject>
- (void)controlsViewLeftPressed:(ControlsView *)controlsView;
- (void)controlsViewRightPressed:(ControlsView *)controlsView;
- (void)controlsView:(ControlsView *)controlsView sliderStartedTracking:(float)value;
- (void)controlsView:(ControlsView *)controlsView sliderStoppedTracking:(float)value;
- (void)controlsView:(ControlsView *)controlsView sliderValueChanged:(float)value;
@end

/// onscreen controls base class
@interface ControlsView : UIView {
	NSLayoutConstraint *heightConstraint;
	NSLayoutConstraint *toolbarHeightConstraint;
	NSLayoutConstraint *sliderLeadingConstraint;
	NSLayoutConstraint *sliderTrailingConstraint;
}

/// controls event delegate
@property (assign, nonatomic) id<ControlsViewDelegate> delegate;

/// override for customization
- (id)initWithFrame:(CGRect)frame;

#pragma mark UI

/// toolbar along top
@property (strong, nonatomic) UIToolbar *toolbar;

/// left toolbar button
@property (strong, nonatomic) UIBarButtonItem *leftButton;

/// right toolbar button
@property (strong, nonatomic) UIBarButtonItem *rightButton;

/// slider centered underneath toolbar
@property (strong, nonatomic) UISlider *slider;

/// use a light background?
/// if YES view is light/dark mode aware, if NO view is black
@property (assign, nonatomic) BOOL lightBackground;

/// override to customize the left toolbar button
- (UIBarButtonItem *)createLeftButton;

/// override to customize the right toolbar button
- (UIBarButtonItem *)createRightButton;

/// override to customize the slider
- (UISlider *)createSlider;

/// control event methods which call delegate methods,
/// override to handle a control change manually
- (void)buttonPressed:(id)sender;
- (void)sliderStartedTracking:(id)sender;
- (void)sliderStoppedTracking:(id)sender;
- (void)sliderValueChanged:(id)sender;

#pragma mark Sizing

/// constraint constants
@property (assign, nonatomic) float height; // controls the height constraint
@property (assign, nonatomic) float spacing; // toolbar button width & slider leading/trailing space
@property (assign, nonatomic) float toolbarHeight; // toolbar height & slider center y

/// default values
@property (readonly, nonatomic) float defaultHeight;
@property (readonly, nonatomic) float defaultSpacing;
@property (readonly, nonatomic) float defaultToolbarHeight;

/// base sizing per the device w/ tablet 2x larger than phone
+ (float)baseWidth;
+ (float)baseHeight;
+ (float)baseSpacing;
+ (float)baseToolbarHeight;

/// sets overall sizing
- (void)halfSize;
- (void)defaultSize;

#pragma Layout

/// align edges to superview
- (void)alignToSuperview;

/// align edges to superview sides & bottom
- (void)alignToSuperviewBottom;

/// align edges to superview sides & top
- (void)alignToSuperviewTop;

@end
