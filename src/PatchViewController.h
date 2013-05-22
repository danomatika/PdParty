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

#import "KeyGrabber.h"

// what kind of scene are we running?
typedef enum {
	SceneTypeEmpty,	// nothing loaded
	SceneTypePatch, // basic pd patch
	SceneTypeRj,	// RjDj scene (folder with .rj ext & _main.pd)
	SceneTypeDroid,	// DroidParty scene (folder with droidparty_main.pd)
	SceneTypeParty	// PdParty scene (folder with _main.pd)
} SceneType;

@class Gui;

// DetailViewController for patches/scenes 
@interface PatchViewController : UIViewController <UISplitViewControllerDelegate, UIAccelerometerDelegate, KeyGrabberDelegate>

@property (strong) Gui *gui; // pd gui widgets

// full path to current patch, the gui is loaded when setting this
@property (strong, nonatomic) NSString* patch;

// current patch scene type, set to SceneTypeEmpty if patch is set to nil or did not load correctly
@property (assign, nonatomic) SceneType sceneType;

@property (assign, nonatomic) BOOL enableAccelerometer; // enable receiving accel events?

#pragma mark RJ Controls

@property (weak, nonatomic) IBOutlet UIView *rjControlsView;
@property (weak, nonatomic) IBOutlet UIButton *rjPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *rjRecordButton;
@property (weak, nonatomic) IBOutlet UISlider *rjInputLevelSlider;

- (IBAction)rjControlChanged:(id)sender;

#pragma Util

// convert an orientation into degrees
+ (int)orientationInDegrees:(UIInterfaceOrientation)orientation;

// convert scene type to a string
+ (NSString*)sceneTypeAsString:(SceneType)type;

@end
