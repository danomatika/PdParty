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
	SceneTypeParty	// PdParty scene (folder with _main.pd)
} SceneType;

// base empty scene
@interface Scene : NSObject

@property (readonly, nonatomic) SceneType type;
@property (readonly, nonatomic) NSString *typeString;

@property (strong, nonatomic) PdFile *patch;
@property (readonly, nonatomic) NSString *name; // scene name

// set these before calling the open method
@property (weak, nonatomic) UIView *parentView; // parent UIView
@property (weak, nonatomic) Gui *gui;			// PD gui (optional, leave nil if not used)

// scene type settings
@property (readonly, nonatomic) int sampleRate; // desired scene sample rate (default PARTY_SAMPLERATE)
//@property (readonly, nonatomic) BOOL requiresTouch; // does the scene require touch events? (default NO)
@property (readonly, nonatomic) BOOL requiresAccel; // does the scene require accel events? (default NO)
@property (readonly, nonatomic) BOOL requiresRotation; // does the scene require rotation events? (default NO)
@property (readonly, nonatomic) BOOL requiresKeys; // does the scene require key events? (default NO)

- (BOOL)open:(NSString*)path; // expects full path
- (void)close;

- (void)reshape;

// attempts to scale a touch within the parent view,
// returns NO if touch not within current scene or scene doesn't require touch events
- (BOOL)scaleTouch:(UITouch*)touch forPos:(CGPoint*)pos;

#pragma mark Util

// add subfolders in libs folder in resource patches dir to search path
- (void)addPatchLibSearchPaths;

@end
