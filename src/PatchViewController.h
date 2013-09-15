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
#import "ControlsView.h"
#import "KeyGrabber.h"

// DetailViewController for patches/scenes 
@interface PatchViewController : UIViewController <UISplitViewControllerDelegate, KeyGrabberDelegate>

// force a rotation of the view in degrees
@property (assign, nonatomic) int rotation;

// on screen audio controls
@property (strong, nonatomic) ControlsView *controlsView;

#pragma mark Scene Management

@property (weak, nonatomic) SceneManager *sceneManager;

// close the current scene and open a new one, requires full path to current patch
- (void)openScene:(NSString *)path withType:(SceneType)type;

// close the current scene
- (void)closeScene;

#pragma mark UI

// called when a right nav bar button is pressed
- (void)navButtonPressed:(id)sender;

@end
