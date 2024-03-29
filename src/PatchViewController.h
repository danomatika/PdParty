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
#import "SceneControlsView.h"
#import "MenuViewController.h"
#import "KeyGrabber.h"

/// DetailViewController for patches/scenes
@interface PatchViewController : UIViewController <UISplitViewControllerDelegate, KeyGrabberDelegate>

/// onscreen/popup scene controls
@property (strong, nonatomic) SceneControlsView *controlsView;

/// popup grid of menu buttons
@property (strong, nonatomic) MenuViewController *menuViewController;

/// loaded background image, used if scene didn't load or there is no scene
@property (strong, nonatomic) UIImageView *background;

#pragma mark Scene Management

@property (weak, nonatomic) SceneManager *sceneManager;

/// close the current scene and open a new one, requires full path to current patch
- (void)openScene:(NSString *)path withType:(NSString *)type;

/// close the current scene
- (void)closeScene;

#pragma mark UI

/// hide left back nav bar button? (default NO)
@property (assign, nonatomic) BOOL hidesBackButton;

/// hide right controls/info nav bar button? (default NO)
@property (assign, nonatomic) BOOL hidesControlsButton;

/// called when a right nav bar button is pressed
- (void)controlsNavButtonPressed:(id)sender;
- (void)infoNavButtonPressed:(id)sender;

/// dismiss master popover if visible
- (void)dismissMasterPopover;

@end
