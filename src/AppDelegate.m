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

// recursively copy dirs and patches in the resource patches dir to the
// Documents folder, removes/overwrites any currently existing dirs
- (void)copyResourcePatchesToDocuments;

//// add subfolders in libs folder in resource patches dir to search path
//- (void)addPatchLibSearchPaths;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	
	if([Util isDeviceATablet]) {
	    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	    splitViewController.delegate = (id)navigationController.topViewController;
		splitViewController.presentsWithGesture = NO; // disable swipe gesture for master view
	}
	
	// init logger
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[[DDFileLogger alloc] init]];
	//ddLogLevel = [preferences logLevel];
	DDLogInfo(@"Log level: %d", ddLogLevel);
	
	DDLogInfo(@"App resolution: %d %d", (int)[Util appWidth], (int)[Util appHeight]);
	
	// copy patches in the resource folder
	[self copyResourcePatchesToDocuments];
	
	// setup midi
	self.midi = [[Midi alloc] init];
	self.midi.networkEnabled = YES;
	
	// setup pd
	self.pureData = [[PureData alloc] init];
	self.pureData.midi = self.midi;
	[Widget setDispatcher:self.pureData.dispatcher];
//	[self addPatchLibSearchPaths];
	
	// setup osc
	self.osc = [[Osc alloc] init];
	
	// init motion manager
	self.motionManager = [[CMMotionManager alloc] init];
	
	// turn on dsp
	self.pureData.audioEnabled = YES;
	
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

#pragma mark Private

- (void)copyResourcePatchesToDocuments {
	
	NSError *error;
	
	DDLogVerbose(@"Copying resource patches to Documents");
	
	// remove existing folders
	NSString* testPatchesPath = [[Util documentsPath] stringByAppendingPathComponent:@"tests"];
	if([[NSFileManager defaultManager] fileExistsAtPath:testPatchesPath]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:testPatchesPath error:&error]) {
			DDLogError(@"Couldn't remove %@, error: %@", testPatchesPath, error.localizedDescription);
		}
	}
	NSString* libPatchesPath = [[Util documentsPath] stringByAppendingPathComponent:@"lib"];
	if([[NSFileManager defaultManager] fileExistsAtPath:libPatchesPath]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:libPatchesPath error:&error]) {
			DDLogError(@"Couldn't remove %@, error: %@", libPatchesPath, error.localizedDescription);
		}
	}
	
	// recursively copy contents of patches resource folder to Documents
	NSString *resourcePatchesPath = [[Util bundlePath] stringByAppendingPathComponent:@"patches"];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePatchesPath error:&error];
	if(!contents) {
		DDLogError(@"Couldn't read files in path %@, error: %@", resourcePatchesPath, error.localizedDescription);
		return;
	}
	
	DDLogVerbose(@"Found %d paths in patches resource folder", contents.count);
	for(NSString *p in contents) {
		NSString *filePath = [resourcePatchesPath stringByAppendingPathComponent:p];
		NSString *destPath = [[Util documentsPath] stringByAppendingPathComponent:p];
		DDLogVerbose(@"	Copying %@", p);
		if(![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destPath error:&error]) {
			DDLogError(@"Couldn't copy %@ to %@, error: %@", filePath, destPath, error.localizedDescription);
		}
	}
}

//- (void)addPatchLibSearchPaths {
//	
//	NSError *error;
//	
//	DDLogVerbose(@"Adding library patches to search path");
//	
//	NSString * libPatchesPath = [[Util bundlePath] stringByAppendingPathComponent:@"patches/lib"];
//	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libPatchesPath error:&error];
//	if(!contents) {
//		DDLogError(@"Couldn't read files in path %@, error: %@", libPatchesPath, error.localizedDescription);
//		return;
//	}
//	
//	DDLogVerbose(@"Found %d paths in resources patches lib folder", contents.count);
//	for(NSString *p in contents) {
//		NSString *path = [libPatchesPath stringByAppendingPathComponent:p];
//		if([Util isDirectory:path]) {
//			DDLogVerbose(@"	Added %@ to search path", p);
//			[PdBase addToSearchPath:path];
//		}
//	}
//}

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
