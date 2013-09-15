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

#import "SceneManager.h"

// RjDj-inspired onscreen controls
@interface ControlsView : UIView <PdPlaybackDelegate>

// make sure to set this or nothing will happen ...
@property (weak, nonatomic) SceneManager *sceneManager;

#pragma mark UI

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *leftButton;
@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UISlider *levelSlider;

- (void)controlChanged:(id)sender;

// update the controls based on the current PureData settings
- (void)updateControls;

//- (void)readdConstraints;

#pragma mark Sizing

// constraint constants
@property (assign, nonatomic) float height; // controls the height constraint
@property (assign, nonatomic) float spacing; // toolbar button / slider space
@property (assign, nonatomic) float toolbarHeight; // toolbar height & slider center y

// default values
@property (readonly, nonatomic) float defaultHeight;
@property (readonly, nonatomic) float defaultSpacing;
@property (readonly, nonatomic) float defaultToolbarHeight;

// sets overall sizing
- (void)halfDefaultSize;
- (void)defaultSize;

@end
