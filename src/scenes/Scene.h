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

@class PdFile;
@class Gui;

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

// set these before calling the open method
@property (weak, nonatomic) UIView *parentView; // parent UIView
@property (weak, nonatomic) Gui *gui;			// PD gui (optional, leave nil if not used)

- (BOOL)open:(NSString*)path; // expects full path
- (void)close;

- (void)reshape;

// attempts to scale a touch within the parent view,
// returns NO if touch not within current scene
- (BOOL)scaleTouch:(UITouch*)touch forPos:(CGPoint*)pos;

#pragma mark Util

// add subfolders in libs folder in resource patches dir to search path
- (void)addPatchLibSearchPaths;

@end
