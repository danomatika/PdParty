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

#import "MBProgressHUD.h"
#import "Unzip.h"
//#import "ZipArchive.h"

#import "Log.h"
#import "Util.h"
#import "Widget.h"

#import "StartViewController.h"
#import "PatchViewController.h"
#import "BrowserViewController.h"
#import "WebViewController.h"

@interface AppDelegate () {
	BOOL audioEnabledWhenBackgrounded; //< YES if the audio was on when we backgrounded
	BOOL serverEnabledWhenBackgrounded; //< YES if the web server was on when backgrounded
}

/// recursively copy a given dir in the resource patches dir to the
/// Documents dir, overwrites any currently existing files with the same name
- (BOOL)copyResourcePatchDirectoryToDocuments:(NSString *)dirPath error:(NSError *)error;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	// light status bar text
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	// setup split view on iPad
	if([Util isDeviceATablet]) {
		UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
		UINavigationController *detailNavController = [splitViewController.viewControllers lastObject];
		splitViewController.delegate = (id)detailNavController.topViewController;
		splitViewController.presentsWithGesture = NO; // disable swipe gesture for master view
		splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
		detailNavController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
		detailNavController.navigationItem.leftItemsSupplementBackButton = NO;
	}
	
	// load defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:
		[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
	
	// init logger
	[Log setup];
	
	DDLogInfo(@"App resolution: %d %d", (int)[Util appWidth], (int)[Util appHeight]);
	
	// copy patches in the resource folder on first run only,
	// blocks UI with progress HUD until done
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"firstRun"]) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
		hud.label.text = @"Setting up for the first time...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[self copyLibDirectory];
			[self copySamplesDirectory];
			[self copyTestsDirectory];
			[defaults setBool:NO forKey:@"firstRun"];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hideAnimated:YES];
			});
		});
	}
	
	// setup app behavior
	self.lockScreenDisabled = [defaults boolForKey:@"lockScreenDisabled"];
	self.runsInBackground = [defaults boolForKey:@"runsInBackground"];
	
	// setup midi
	self.midi = [[MidiBridge alloc] init];
	
	// setup osc
	self.osc = [[Osc alloc] init];
	
	// setup pd
	self.pureData = [[PureData alloc] init];
	[PdBase setMidiDelegate:self.midi pollingEnabled:NO];
	self.pureData.osc = self.osc;
	[Widget setDispatcher:self.pureData.dispatcher];
	
	// setup the scene manager
	self.sceneManager = [[SceneManager alloc] init];
	self.sceneManager.pureData = self.pureData;
	self.sceneManager.osc = self.osc;
	
	// setup webserver
	self.server = [[WebServer alloc] init];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

	// pause while backgrounded?
	if(!self.runsInBackground) {
		audioEnabledWhenBackgrounded = self.pureData.audioEnabled;
		self.pureData.audioEnabled = NO;
		serverEnabledWhenBackgrounded = self.server.isRunning;
		[self.server stop];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

	// restart audio & server
	if(!self.runsInBackground) {
		self.pureData.audioEnabled = audioEnabledWhenBackgrounded;
		if(serverEnabledWhenBackgrounded) {
			[self.server start];
		}
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

	// check for any new controllers
	if(self.sceneManager.controllers.enabled) {
		[self.sceneManager.controllers updateConnectedControllers];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// references:
// http://www.infragistics.com/community/blogs/stevez/archive/2013/03/04/associate-a-file-type-with-your-ios-application.aspx

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
	// called when a registered file type is opened in the Files app, transferred via the Open With... mechanism, or
	// PdParty is invoked via the custom "pdparty://" scheme
	DDLogVerbose(@"AppDelegate: openURL %@ from %@", url, options[UIApplicationOpenURLOptionsSourceApplicationKey]);

	// open in place from Files app or other file provider (iCloud?)
	if(options[UIApplicationOpenURLOptionsOpenInPlaceKey]) {
		// standardize path, otherwise file URLs from the Files app may start with the /private prefix
		NSString *path = url.URLByStandardizingPath.path;
		if(![path hasPrefix:[Util documentsPath]]) {
			// refuse for now, opening single patches works but there doesn;t seem to be an easy way to get permissions
			// to access other files outside of the single security-scoped url
			DDLogError(@"AppDelegate: refused to open path outside of sandbox: %@", path);
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle: @"Open Failed"
								  message: [NSString stringWithFormat:@"Could not open %@ outside of the PdParty sandbox.\n\nPlease copy the patch(es) or scene directory into PdParty.", path.lastPathComponent]
								  delegate: nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil];
			[alert show];
			return NO;
		}
		if(![self tryOpeningPath:path]) {
			DDLogError(@"AppDelegate: couldn't open path in place: %@", path);
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle: @"Open Failed"
								  message: [NSString stringWithFormat:@"Could not open %@", path.lastPathComponent]
								  delegate: nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil];
			[alert show];
			return NO;
		}

		return YES;
	}

	// open patch or scene via "pdparty://" scheme with "open" domain, ie. "pdparty://open/path/to/patch.pd"
	if([url.scheme isEqualToString:@"pdparty"]) {
		if(!url.host || !url.path) {return YES;}  // nothing to do, just open
		if([url.host isEqualToString:@"open"]) {
			NSString *path = [[Util documentsPath] stringByAppendingPathComponent:url.path];
			DDLogVerbose(@"AppDelegate: opening %@", path);
			if(![self tryOpeningPath:path]) {
				DDLogError(@"AppDelegate: couldn't open pdparty url: %@", url.path);
				UIAlertView *alert = [[UIAlertView alloc]
									  initWithTitle: @"Open Failed"
									  message: [NSString stringWithFormat:@"%@ not found in Documents", url.path]
									  delegate: nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil];
				[alert show];
				return NO;
			}
		}
		return YES;
	}

	// copy patch or zip file
	NSError *error;
	NSString *path = [url path];
	NSString *filename = [path lastPathComponent];
	NSString *ext = [path pathExtension];
	
	DDLogVerbose(@"AppDelegate: receiving %@", filename);

	// pd patch
	if([ext isEqualToString:@"pd"]) {
		NSString *newPath = [[Util documentsPath] stringByAppendingPathComponent:[path lastPathComponent]];
		if([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:newPath error:&error]) {
				DDLogError(@"AppDelegate: couldn't remove %@, error: %@", newPath, error.localizedDescription);
			}
		}
		if(![[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"AppDelegate: couldn't move %@, error: %@", path, error.localizedDescription);
			UIAlertView *alert = [[UIAlertView alloc]
			                          initWithTitle: @"Copy Failed"
			                          message: [NSString stringWithFormat:@"Could not copy %@ to Documents", filename]
			                          delegate: nil
			                          cancelButtonTitle:@"OK"
			                          otherButtonTitles:nil];
			[alert show];
			return NO;
		}
		[[NSFileManager defaultManager] removeItemAtURL:url error:&error]; // remove original file

		DDLogVerbose(@"AppDelegate: copied %@ to Documents", filename);
		UIAlertView *alert = [[UIAlertView alloc]
			                          initWithTitle: @"Copy Succeeded"
			                          message: [NSString stringWithFormat:@"%@ copied to Documents", filename]
			                          delegate: nil
			                          cancelButtonTitle:@"OK"
			                          otherButtonTitles:nil];
		[alert show];
	}
	else { // assume zip file
		Unzip *zip = [[Unzip alloc] init];
		if([zip open:path]) {
			if([zip unzipTo:[Util documentsPath] overwrite:YES]) {
				if(![[NSFileManager defaultManager] removeItemAtURL:url error:&error]) { // remove original file
					DDLogError(@"AppDelegate: couldn't remove %@, error: %@", path, error.localizedDescription);
				}
			}
			else{
				DDLogError(@"AppDelegate: couldn't open zipfile: %@", path);
				UIAlertView *alert = [[UIAlertView alloc]
			                          initWithTitle: @"Unzip Failed"
			                          message: [NSString stringWithFormat:@"Could not decompress %@ to Documents", filename]
			                          delegate: nil
			                          cancelButtonTitle:@"OK"
			                          otherButtonTitles:nil];
				[alert show];
			}
			[zip close];
		}
		else {
			DDLogError(@"AppDelegate: couldn't unzip %@ to Documents", path);
			UIAlertView *alert = [[UIAlertView alloc]
			                          initWithTitle: @"Unzip Failed"
			                          message: [NSString stringWithFormat:@"Could not decompress %@ to Documents", filename]
			                          delegate: nil
			                          cancelButtonTitle:@"OK"
			                          otherButtonTitles:nil];
			[alert show];
			return NO;
		}

		DDLogVerbose(@"AppDelegate: unzipped %@ to Documents", filename);
		UIAlertView *alert = [[UIAlertView alloc]
		                          initWithTitle: @"Unzip Succeeded"
		                          message: [NSString stringWithFormat:@"%@ unzipped to Documents", filename]
		                          delegate: nil
		                          cancelButtonTitle:@"OK"
		                          otherButtonTitles:nil];
		[alert show];
	}
	
	// reload if we're in the Documents dir
	[self.browserViewController reloadDirectory];
	
	return YES;
}

#pragma mark Now Playing

// references:
// * http://stackoverflow.com/questions/2071028/want-to-add-uinavigationbar-rightbarbutton-like-now-playing-button-of-ipod-wh
// * LastFM app: https://github.com/c99koder/lastfm-iphone/blob/master/Classes/UIViewController%2BNowPlayingButton.h

- (UIBarButtonItem *)nowPlayingButton {
	if(!self.sceneManager.scene || [Util isDeviceATablet]) {
		return nil;
	}
	return [[UIBarButtonItem alloc] initWithTitle:@"Now Playing"
	                                       style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(nowPlayingPressed:)];
}

- (void)nowPlayingPressed:(id)sender {
	DDLogVerbose(@"AppDelegate: now playing button pressed");
	if([Util isDeviceATablet]) {
		return;
	}
	
	// this should always be set on iPad since it's the detail view,
	// so this code should only be called on iPhone
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	PatchViewController *patchView = app.patchViewController;
	if(!patchView) {
		// create a new patch view and push it on the stack, this occurs on low mem devices
		UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
		patchView = (PatchViewController *)[board instantiateViewControllerWithIdentifier:@"PatchViewController"];
		if(!patchView) {
			DDLogError(@"AppDelegate: couldn't create patch view");
			return;
		}
	}
	UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if([root isKindOfClass:[UINavigationController class]]) {
		[(UINavigationController *)root pushViewController:(UIViewController *)patchView animated:YES];
	}
	else {
		DDLogError(@"AppDelegate: can't push now playing, rootViewController is not a UINavigationController");
	}
}

#pragma mark Path

/// requires full path within the Documents dir
- (BOOL)tryOpeningPath:(NSString *)path {
	BOOL opened;
	UINavigationController *nav = self.startViewController.navigationController;
	BrowserViewController *browser = self.browserViewController;
	if(browser) {
		// pop view stack to browser
		[nav popToViewController:browser animated:NO];
		opened = [browser tryOpeningPath:path];
	}
	else {
		// browser may be nil on phone, so push from start view
		[nav popToViewController:self.startViewController animated:NO];
		NSString *name = ([Util isDeviceATablet] ? @"MainStoryboard_iPad" : @"MainStoryboard_iPhone");
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
		browser = [storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
		[nav pushViewController:browser animated:NO];
		opened = [browser tryOpeningPath:path];
	}
	if(!opened) {
		// reset
		[browser loadDocumentsDirectory];
	}
	return opened;
}

#pragma mark URL

- (void)launchWebViewForURL:(NSURL *)url withTitle:(NSString *)title sceneRotationsOnly:(BOOL)sceneRotationsOnly {

	// open url in web view
	WebViewController *controller = [[WebViewController alloc] init];
	[controller openURL:url withTitle:title sceneRotationsOnly:sceneRotationsOnly];
	
	// wrap web view in nav controller
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
	nav.navigationBar.barStyle = UIBarStyleBlack;

	// present nav controller
	UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	[self.patchViewController dismissMasterPopover]; // hide master popover if visible
	[root presentViewController:nav animated:YES completion:nil];
}

#pragma mark Util

- (void)copyLibDirectory {
	NSError *error;
	if(![self copyResourcePatchDirectoryToDocuments:@"lib" error:error]) {
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Couldn't lib samples folder"
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)copySamplesDirectory {
	NSError *error;
	UIAlertView *alertView;
	if(![self copyResourcePatchDirectoryToDocuments:@"samples" error:error]) {
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Couldn't copy samples folder"
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)copyTestsDirectory {
	NSError *error;
	UIAlertView *alertView;
	if(![self copyResourcePatchDirectoryToDocuments:@"tests" error:error]) {
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Couldn't copy tests folder"
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
	}
}

#pragma mark Overridden Getters / Setters

- (BOOL)isPatchViewVisible {
	return self.patchViewController && self.patchViewController.isViewLoaded && self.patchViewController.view.window;
}

- (void)setLockScreenDisabled:(BOOL)lockScreenDisabled {
	_lockScreenDisabled = lockScreenDisabled;
	[[UIApplication sharedApplication] setIdleTimerDisabled:lockScreenDisabled];
	[[NSUserDefaults standardUserDefaults] setBool:lockScreenDisabled forKey:@"lockScreenDisabled"];
}

- (void)setRunsInBackground:(BOOL)runsInBackground {
	_runsInBackground = runsInBackground;
	[[NSUserDefaults standardUserDefaults] setBool:runsInBackground forKey:@"runsInBackground"];
}

#pragma mark Private

- (BOOL)copyResourcePatchDirectoryToDocuments:(NSString *)dirPath error:(NSError *)error {
	DDLogVerbose(@"AppDelegate: copying %@ to Documents", dirPath);
	
	// create dest folder if it doesn't exist
	NSString* destPath = [[Util documentsPath] stringByAppendingPathComponent:dirPath];
	if(![[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:NO attributes:NULL error:&error]) {
			DDLogError(@"AppDelegate: couldn't create %@, error: %@", destPath, error.localizedDescription);
			return NO;
		}
	}
	
	// patch folder resources are in patches/*
	NSString *srcPath = [[[Util bundlePath] stringByAppendingPathComponent:@"patches"] stringByAppendingPathComponent:dirPath];
	
	// recursively copy all items within src into dest, this way we don't lose any other files or folders added by the user
	return [Util copyContentsOfDirectory:srcPath toDirectory:destPath error:error];
}

@end

#pragma mark UINavigationController Rotation

/// category to force all UINavigationControllers to do rotations
/// based on the top view controller
/// http://stackoverflow.com/questions/12520030/how-to-force-a-uiviewcontroller-to-portait-orientation-in-ios-6/12522119#12522119
@implementation UINavigationController (Rotation_IOS6)

- (BOOL)shouldAutorotate {
	return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	return [self.topViewController preferredInterfaceOrientationForPresentation];
}

@end

#pragma mark UISplitViewController Rotation

/// needed for rotation on iPad since SplitViewController is root controller
@implementation UISplitViewController (Rotation_IOS6)

- (BOOL)shouldAutorotate {
	return [[self.viewControllers lastObject] shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end
