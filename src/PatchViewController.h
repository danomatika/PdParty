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
#import "KeyGrabber.h"

// DetailViewController for patches/scenes 
@interface PatchViewController : UIViewController
	<UISplitViewControllerDelegate, KeyGrabberDelegate, PdPlaybackDelegate>

@property (weak, nonatomic) SceneManager *sceneManager;

// close the current scene and open a new one, requires full path to current patch
- (void)openScene:(NSString *)path withType:(SceneType)type;

// close the current scene
- (void)closeScene;

#pragma mark RJ Controls

@property (weak, nonatomic) IBOutlet UIView *rjControlsView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rjPauseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rjRecordButton;
@property (weak, nonatomic) IBOutlet UISlider *rjInputLevelSlider;

- (IBAction)rjControlChanged:(id)sender;

// update the rj controls based on the current PureData settings
- (void)updateRjControls;

@end
