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
#import "AppDelegate.h"

#import "Log.h"
#import "Util.h"
#import "Widget.h"

#import "PatchViewController.h"

@interface AppDelegate ()

// recursively copy a given folder in the resource patches dir to the
// Documents folder, removes/overwrites any currently existing dirs
- (void)copyResourcePatchFolderToDocuments:(NSString *)folderPath;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	
	// setup split view on iPad
	if([Util isDeviceATablet]) {
	    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	    splitViewController.delegate = (id)navigationController.topViewController;
		splitViewController.presentsWithGesture = NO; // disable swipe gesture for master view
	}
	
	// load defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:
		[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
	
	// init logger
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[[DDFileLogger alloc] init]];
	ddLogLevel = [defaults integerForKey:@"logLevel"];
	DDLogInfo(@"Log level: %d", ddLogLevel);
	
	DDLogInfo(@"App resolution: %d %d", (int)[Util appWidth], (int)[Util appHeight]);
	
	// copy patches in the resource folder on first run only
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"firstRun"]) {
		[self copyLibFolder];
		[self copySamplesFolder];
		[self copyTestsFolder];
		[defaults setBool:NO forKey:@"firstRun"];
	}
	
	// setup midi
	self.midi = [[Midi alloc] init];
	self.midi.networkEnabled = YES;
	
	// setup osc
	self.osc = [[Osc alloc] init];
	
	// setup pd
	self.pureData = [[PureData alloc] init];
	self.pureData.midi = self.midi;
	self.pureData.osc = self.osc;
	[Widget setDispatcher:self.pureData.dispatcher];
	
	// setup the scene manager
	self.sceneManager = [[SceneManager alloc] init];
	self.sceneManager.pureData = self.pureData;
	self.sceneManager.osc = self.osc;
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	
	self.pureData.audioEnabled = NO;
	self.osc.listening = NO;
	self.midi.networkEnabled = NO;
}

#pragma mark Util

- (void)copyLibFolder {
	[self copyResourcePatchFolderToDocuments:@"lib"];
}

- (void)copySamplesFolder {
	[self copyResourcePatchFolderToDocuments:@"samples"];
}

- (void)copyTestsFolder {
	[self copyResourcePatchFolderToDocuments:@"tests"];
}

#pragma mark Private

- (void)copyResourcePatchFolderToDocuments:(NSString *)folderPath {
	
	NSError *error;
	
	DDLogVerbose(@"AppDelegate: copying %@ to Documents", folderPath);
	
	// remove existing folder
	NSString* destPath = [[Util documentsPath] stringByAppendingPathComponent:folderPath];
	if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:destPath error:&error]) {
			DDLogError(@"AppDelegate: couldn't remove %@, error: %@", destPath, error.localizedDescription);
		}
	}
	
	// copy
	NSString* srcPath = [[[Util bundlePath] stringByAppendingPathComponent:@"patches"] stringByAppendingPathComponent:folderPath];
	if(![[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:destPath error:&error]) {
		DDLogError(@"AppDelegate: couldn't copy %@ to %@, error: %@", srcPath, destPath, error.localizedDescription);
	}
}

@end

#pragma mark UINavigationController Rotation

// category to force all UINavigationControllers to do rotations
// based on the top view controller
// http://stackoverflow.com/questions/12520030/how-to-force-a-uiviewcontroller-to-portait-orientation-in-ios-6/12522119#12522119
@implementation UINavigationController (Rotation_IOS6)

- (BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end

#pragma mark UISplitViewController Rotation

// needed for rotation on iPad since SplitViewController is root controller
@implementation UISplitViewController (Rotation_IOS6)

- (BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end
