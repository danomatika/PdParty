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

#import "AllScenes.h"
#import "KeyGrabber.h"

@class Gui;

// DetailViewController for patches/scenes 
@interface PatchViewController : UIViewController
	<UISplitViewControllerDelegate, UIAccelerometerDelegate, KeyGrabberDelegate>

@property (strong) Gui *gui; // pd gui widgets
@property (strong, nonatomic) Scene* scene; // current scene

// touch events handled automatically
@property (assign, nonatomic) BOOL enableAccelerometer; // enable receiving accel events?
@property (assign, nonatomic) BOOL enableRotation;		// enable rotation events?
@property (assign, nonatomic) BOOL enableKeyGrabber;	// enable keyboard event grabbing?

// close the current scene and open a new one, requires full path to current patch
- (void)openScene:(NSString*)path withType:(SceneType)type;

// close the current scene
- (void)closeScene;

#pragma mark RJ Controls

@property (weak, nonatomic) IBOutlet UIView *rjControlsView;
@property (weak, nonatomic) IBOutlet UIButton *rjPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *rjRecordButton;
@property (weak, nonatomic) IBOutlet UISlider *rjInputLevelSlider;

- (IBAction)rjControlChanged:(id)sender;

// update the rj controls based on the current PureData settings
- (void)updateRjControls;

#pragma Util

// convert an orientation into degrees
+ (int)orientationInDegrees:(UIInterfaceOrientation)orientation;

@end
