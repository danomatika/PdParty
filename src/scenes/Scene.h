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

#import "PureData.h"
#import "Gui.h"

#import "Log.h"
#import "Util.h"

// what kind of scene are we running?
typedef enum {
	SceneTypeEmpty,	// nothing loaded
	SceneTypePatch, // basic pd patch
	SceneTypeRj,	// RjDj scene (folder with .rj ext & _main.pd)
	SceneTypeDroid,	// DroidParty scene (folder with droidparty_main.pd)
	SceneTypeParty,	// PdParty scene (folder with _main.pd)
	SceneTypeRecording // dummy scene for recording playback (.wav file)
} SceneType;

// base empty scene
@interface Scene : NSObject

@property (readonly, nonatomic) SceneType type;
@property (readonly, nonatomic) NSString *typeString;

@property (strong, nonatomic) PdFile *patch;
@property (readonly, nonatomic) NSString *name; // scene name
@property (readonly, nonatomic) BOOL records; // can this scene record? has a [soundoutput] object

// rjdj style  scene info, probabaly loaded from a file, etc
@property (readonly, nonatomic) BOOL hasInfo; // returns YES if the current info is good
@property (readonly, nonatomic) NSString *artist; // scene artist name
@property (readonly, nonatomic) NSString *category; // scene category
@property (readonly, nonatomic) NSString *description; // scene description

// set these before calling the open method
@property (weak, nonatomic) UIView *parentView; // parent UIView
@property (weak, nonatomic) Gui *gui;			// PD gui (optional, leave nil if not used)

// scene type settings
@property (readonly, nonatomic) int sampleRate; // desired scene sample rate (default PARTY_SAMPLERATE)
@property (readonly, nonatomic) BOOL requiresTouch; // does the scene require touch events? (default NO)
@property (readonly, nonatomic) BOOL requiresAccel; // does the scene require accel events? (default NO)
@property (readonly, nonatomic) BOOL supportsAccel; // does the scene support accel events? (default NO)
@property (readonly, nonatomic) BOOL supportsMagnet; // does the scene support magnet events? (default NO)
@property (readonly, nonatomic) BOOL supportsGyro; // does the scene support gyro events? (default NO)
@property (readonly, nonatomic) BOOL supportsLocate; // does the scene support locate events? (default NO)
@property (readonly, nonatomic) BOOL supportsHeading; // does the scene support heading events? (default NO)
@property (readonly, nonatomic) BOOL requiresKeys; // does the scene require key events? (default NO)

// preferred orientations, all by default
@property (assign, nonatomic) UIInterfaceOrientationMask preferredOrientations;

// does the scene require on screen controls?
@property (readonly, nonatomic) BOOL requiresOnscreenControls;
@property (readonly, nonatomic) int contentHeight; // used for positioning controls

- (BOOL)open:(NSString *)path; // expects full path
- (void)close;

// reshape to fit current parent view size
- (void)reshape;

// attempts to scale a touch within the parent view,
// returns NO if touch not within current scene or scene doesn't require touch events
- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos;

#pragma mark Util

// add subfolders in a given directory to the PD search path
- (void)addSearchPathsIn:(NSString *)directory;

// compute
+ (UIInterfaceOrientationMask)orientationMaskFromWidth:(float)width andHeight:(float)height;

@end
