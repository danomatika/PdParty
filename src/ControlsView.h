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

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *leftButton;
@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UISlider *levelSlider;

@property (assign, nonatomic) float height; // controls the height constraint

- (void)controlChanged:(id)sender;

// update the controls based on the current PureData settings
- (void)updateControls;

@end
