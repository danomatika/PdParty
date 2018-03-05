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
#import "MidiBridge.h"
#import "Osc.h"
#import "SceneManager.h"
#import "WebServer.h"

@class StartViewController;
@class PatchViewController;
@class BrowserViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/// global access
@property (weak, nonatomic) StartViewController *startViewController;
@property (weak, nonatomic) PatchViewController *patchViewController;
@property (weak, nonatomic) BrowserViewController *browserViewController;

@property (strong, nonatomic) PureData *pureData;
@property (strong, nonatomic) MidiBridge *midi;
@property (strong, nonatomic) Osc *osc;
@property (strong, nonatomic) SceneManager *sceneManager;
@property (strong, nonatomic) WebServer *server;

/// returns whether the patch view is currently visible
@property (readonly, nonatomic) BOOL isPatchViewVisible;

#pragma mark App Behavior

@property (assign, getter=isLockScreenDisabled, nonatomic) BOOL lockScreenDisabled;
@property (assign, nonatomic) BOOL runsInBackground;

#pragma mark Now Playing

/// create "Now Playing" nav bar button, target:self action:@selector(cNowPlayingPressed)
/// returns nil on iPad
- (UIBarButtonItem *)nowPlayingButton;

/// push patch view on sender.navigationController on iPhone, ignored on iPad
- (void)nowPlayingPressed:(id)sender;

#pragma mark Path

/// try opening a path in the Browser:
/// * pops all current views from the stack
/// * open Browser
/// * navigates to parent directory
/// * tries opening path, reloads Documents dir on failure
/// returns YES on success
- (BOOL)tryOpeningPath:(NSString *)path;

#pragma mark URL

/// launch web view for a url, uses app scene folder for relative path
/// set sceneRotationsOnly if launched from a scene
- (void)launchWebViewForURL:(NSURL *)url withTitle:(NSString *)title sceneRotationsOnly:(BOOL)sceneRotationsOnly;

#pragma mark Util

/// recursively copy dirs and patches in the resource patches dir to the
/// Documents dir, removes/overwrites any currently existing subdirs matching
/// those within the source dir
- (void)copyLibDirectory;
- (void)copySamplesDirectory;
- (void)copyTestsDirectory;

@end
