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

#import "Log.h"
#import "Util.h"
#import "Widget.h"

#import "StartViewController.h"
#import "PatchViewController.h"
#import "BrowserViewController.h"
#import "WebViewController.h"

NSString *const PdPartyMotionShakeEndedNotification = @"PdPartyMotionShakeEndedNotification";

@interface AppDelegate () {
	BOOL audioEnabledWhenBackgrounded; ///< YES if the audio was on when we backgrounded
	BOOL serverEnabledWhenBackgrounded; ///< YES if the web server was on when backgrounded
}

/// recursively copy a given dir in the resource patches dir to the
/// Documents dir, overwrites any currently existing files with the same name
- (BOOL)copyResourcePatchDirectoryToDocuments:(NSString *)dirPath error:(NSError *)error;

@end

@implementation AppDelegate

 // call only once
- (void)setup {
	static BOOL setup = NO;
	if(setup) {return;}
	setup = YES;

	// load defaults
	NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
	[defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:
		[NSBundle.mainBundle pathForResource:@"Defaults" ofType:@"plist"]]];

	// load optional config, overrides defaults
	NSArray *configPaths = [Util whichFilenames:@[@"config.json", @"Config.json"] existInDirectory:Util.documentsPath];
	if(configPaths) {
		NSLog(@"AppDelegate: loading %@", [configPaths.firstObject lastPathComponent]);
		[self loadConfigFile:configPaths.firstObject];
	}

	// init logger
	[Log setup];

	// set up midi
	self.midi = [[MidiBridge alloc] init];

	// set up osc
	self.osc = [[Osc alloc] init];

	// set up pd
	self.pureData = [[PureData alloc] init];
	[PdBase setMidiDelegate:self.midi pollingEnabled:NO];
	self.pureData.osc = self.osc;
	[Widget setDispatcher:self.pureData.dispatcher];

	// set up the scene manager
	self.sceneManager = [[SceneManager alloc] init];
	self.sceneManager.pureData = self.pureData;
	self.sceneManager.osc = self.osc;

	// set up webserver
	self.server = [[WebServer alloc] init];

	// set up app behavior
	self.lockScreenDisabled = [defaults boolForKey:@"lockScreenDisabled"];
	self.runsInBackground = [defaults boolForKey:@"runsInBackground"];

	LogInfo(@"AppDelegate: app resolution %g %g", Util.appWidth, Util.appHeight);

	// copy patches in the resource folder on first run only,
	// blocks UI with progress HUD until done
	if([NSUserDefaults.standardUserDefaults boolForKey:@"firstRun"]) {
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

	// clear any Documents/Inbox leftovers
	NSString *inboxPath = [Util.documentsPath stringByAppendingPathComponent:@"Inbox"];
	if([NSFileManager.defaultManager fileExistsAtPath:inboxPath]) {
		[Util deleteContentsOfDirectory:inboxPath error:nil];
	}
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	// set up split view on iPad
	if(Util.isDeviceATablet) {
		UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
		UINavigationController *detailNavController = splitViewController.viewControllers.lastObject; // PatchViewController
		splitViewController.delegate = (id)detailNavController.topViewController;
		splitViewController.presentsWithGesture = NO; // disable swipe gesture for master view
		splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
		detailNavController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
		detailNavController.navigationItem.leftItemsSupplementBackButton = NO;
	}
	else { // light content as default is black text on black nav bar
		UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleLightContent;
	}

	// set up globals, etc
	[self setup];

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
	// Called when a registered file type is opened in the Files app, transferred via the Open With... mechanism, or
	// PdParty is invoked via the custom "pdparty://" scheme.

	NSString *path = nil;
	LogVerbose(@"AppDelegate: openURL %@ from %@", url, options[UIApplicationOpenURLOptionsSourceApplicationKey]);

	// open patch or scene via "pdparty://" scheme with "open" domain, ie. "pdparty://open/path/to/patch.pd"
	if([url.scheme isEqualToString:@"pdparty"] && url.path) {
		if([url.host isEqualToString:@"open"]) {
			path = [Util.documentsPath stringByAppendingPathComponent:url.path];
		}
		else { // other message types currently ignored
			LogWarn(@"AppDelegate: ignoring unknown pdparty:// message type: %@", url.host);
			return NO;
		}
	}
	// open in place from Files app or other file provider (iCloud?)
	else if(options[UIApplicationOpenURLOptionsOpenInPlaceKey] &&
	        [options[UIApplicationOpenURLOptionsOpenInPlaceKey] boolValue]) {
		// standardize path, otherwise file URLs from the Files app may start with the /private prefix
		path = url.URLByStandardizingPath.path;
	}
	if(path) {
		LogVerbose(@"AppDelegate: opening path: %@", path);
		if(![path hasPrefix:Util.documentsPath]) {
			// refuse for now, opening single patches works but there doesn't seem to be an easy way to get permissions
			// to access other files outside of the single security-scoped url
			LogError(@"AppDelegate: refused to open path outside of sandbox: %@", path);
			NSString *message = [NSString stringWithFormat:@"Could not open %@ outside of the PdParty sandbox.\n\nPlease copy the patch(es) or scene directory into PdParty.", path.lastPathComponent];
			[[UIAlertController alertControllerWithTitle:@"Open Failed"
			                                     message:message
			                           cancelButtonTitle:@"Ok"] show];
			return NO;
		}
		if(![self openPath:path]) {
			LogError(@"AppDelegate: couldn't open path: %@", path);
			NSString *message = [NSString stringWithFormat:@"Could not open %@", path.lastPathComponent];
			[[UIAlertController alertControllerWithTitle:@"Open Failed"
			                                     message:message
			                           cancelButtonTitle:@"Ok"] show];
			return NO;
		}
		return YES;
	}
	if(!url.path) { // nothing to open?
		return NO;
	}

	// copy patch or zip file from Documents/Inbox
	NSError *error;
	path = url.path;
	NSString *filename = path.lastPathComponent;
	LogVerbose(@"AppDelegate: receiving %@", filename);

	// pd patch
	if([path.pathExtension isEqualToString:@"pd"]) {
		NSString *newPath = [Util.documentsPath stringByAppendingPathComponent:path.lastPathComponent];
		newPath = [Util generateCopyPathForPath:newPath];
		if(![NSFileManager.defaultManager copyItemAtPath:path toPath:newPath error:&error]) {
			LogError(@"AppDelegate: couldn't copy %@, error: %@", path, error.localizedDescription);
			NSString *message = [NSString stringWithFormat:@"Could not copy %@ to Documents", filename];
			[[UIAlertController alertControllerWithTitle:@"Copy Failed"
			                                     message:message
			                           cancelButtonTitle:@"Ok"] show];
			return NO;
		}
		[NSFileManager.defaultManager removeItemAtURL:url error:&error]; // remove original file
		LogVerbose(@"AppDelegate: copied %@ to Documents", filename);
		NSString *message = [NSString stringWithFormat:@"%@ copied to Documents", newPath.lastPathComponent];
		[[UIAlertController alertControllerWithTitle:@"Copy Succeeded"
		                                     message:message
		                           cancelButtonTitle:@"Ok"] show];
		[self.browserViewController reloadDirectory];
	}
	else { // assume zip file
		if([BrowserViewController unzipPath:path toDirectory:Util.documentsPath]) {
			NSString *message = [NSString stringWithFormat:@"%@ unzipped to Documents", filename];
			[[UIAlertController alertControllerWithTitle:@"Unzip Succeeded"
			                                     message:message
			                           cancelButtonTitle:@"Ok"] show];
		}
		else {
			// remove original file
			[NSFileManager.defaultManager removeItemAtURL:url error:nil];
		}
	}
	
	// reload if we're in the Documents dir
	if([self.browserViewController.directory isEqualToString:Util.documentsPath]) {
		LogInfo(@"AppDelegate: reloading Documents dir");
		[self.browserViewController reloadDirectory];
	}
	
	return YES;
}

#pragma mark Now Playing

// references:
// * http://stackoverflow.com/questions/2071028/want-to-add-uinavigationbar-rightbarbutton-like-now-playing-button-of-ipod-wh
// * LastFM app: https://github.com/c99koder/lastfm-iphone/blob/master/Classes/UIViewController%2BNowPlayingButton.h

- (UIBarButtonItem *)nowPlayingButton {
	if(!self.sceneManager.scene || Util.isDeviceATablet) {
		return nil;
	}
	return [[UIBarButtonItem alloc] initWithTitle:@"Now Playing"
	                                       style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(nowPlayingPressed:)];
}

- (void)nowPlayingPressed:(id)sender {
	LogVerbose(@"AppDelegate: now playing button pressed");
	if(Util.isDeviceATablet) {
		return;
	}
	
	// this should always be set on iPad since it's the detail view,
	// so this code should only be called on iPhone
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	PatchViewController *patchView = app.patchViewController;
	if(!patchView) {
		// create a new patch view and push it on the stack, this occurs on low mem devices
		UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
		patchView = (PatchViewController *)[board instantiateViewControllerWithIdentifier:@"PatchViewController"];
		if(!patchView) {
			LogError(@"AppDelegate: couldn't create patch view");
			return;
		}
	}
	UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
	if([root isKindOfClass:UINavigationController.class]) {
		[(UINavigationController *)root pushViewController:(UIViewController *)patchView animated:YES];
	}
	else {
		LogError(@"AppDelegate: can't push now playing, rootViewController is not a UINavigationController");
	}
}

#pragma mark Path

/// requires full path within the Documents dir
- (BOOL)openPath:(NSString *)path {
	BOOL opened;
	UINavigationController *nav = self.startViewController.navigationController;
	BrowserViewController *browser = self.browserViewController;
	if(browser) {
		// pop view stack to browser
		[nav popToViewController:browser animated:NO];
		opened = [browser openPath:path];
	}
	else {
		// browser may be nil on phone, so push from start view
		[nav popToViewController:self.startViewController animated:NO];
		NSString *name = (Util.isDeviceATablet ? @"MainStoryboard_iPad" : @"MainStoryboard_iPhone");
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
		browser = [storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
		[nav pushViewController:browser animated:NO];
		opened = [browser openPath:path];
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

	// opaque nav bar if content is scrollable
	if(@available(iOS 13.0, *)) {
		nav.navigationBar.scrollEdgeAppearance = nav.navigationBar.standardAppearance;
	}

	// present nav controller
	UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
	[self.patchViewController dismissMasterPopover]; // hide master popover if visible
	[root presentViewController:nav animated:YES completion:nil];
}

#pragma mark Config

//#define DEBUG_CONFIG

#define DICT_EXISTS(parent, name) parent[name] && [parent[name] isKindOfClass:NSDictionary.class]
#define STRING_EXISTS(parent, name) parent[name] && [parent[name] isKindOfClass:NSString.class]
#define NUMBER_EXISTS(parent, name) parent[name] && [parent[name] isKindOfClass:NSNumber.class]

#define READ_BOOL(parent, name, defaultkey) \
if(NUMBER_EXISTS(parent, name)) { \
	BOOL b = [parent[name] boolValue]; \
	kvpairs[defaultkey] = (b ? @YES : @NO); \
}

#define READ_STRING(parent, name, defaultkey) \
if(STRING_EXISTS(parent, name)) { \
	NSString *s = parent[name]; \
	kvpairs[defaultkey] = s; \
}

#define READ_PORT(parent, name, defaultkey) \
if(NUMBER_EXISTS(parent, name)) { \
	int i = [parent[name] intValue]; \
	if(i > 1024) {kvpairs[defaultkey] = @(i);} \
}

- (void)loadConfigFile:(NSString *)path {
	path = [Util.documentsPath stringByAppendingPathComponent:path];
	NSError *error;
	id data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:0 error:&error];
	if(!data) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			LogError(@"AppDelegate: parsing JSON from %@ failed: %@", path, error.debugDescription);
			NSString *title = [NSString stringWithFormat:@"Parsing %@ failed", path.lastPathComponent];
			[[UIAlertController alertControllerWithTitle:title
		                                         message:error.userInfo[NSDebugDescriptionErrorKey]
		                               cancelButtonTitle:@"Ok"] show];
		});
		return;
	}
	if(![data isKindOfClass:NSDictionary.class]) {return;}
	NSDictionary *config = data, *dict = nil;
	NSMutableDictionary *kvpairs = [NSMutableDictionary new]; // defaultsKey: value
	if(DICT_EXISTS(config, @"audio")) {
		dict = config[@"audio"];
		if(NUMBER_EXISTS(dict, @"micvolume")) {
			float f = CLAMP([dict[@"micvolume"] floatValue], 0, 1);
			kvpairs[@"micVolume"] = @(f);
		}
	}
	if(DICT_EXISTS(config, @"osc")) {
		dict = config[@"osc"];
		READ_BOOL(dict, @"enabled", @"oscServerEnabled");
		if(DICT_EXISTS(dict, @"send")) {
			READ_STRING(dict[@"send"], @"host", @"oscSendHost");
			READ_PORT(dict[@"send"], @"port", @"oscSendPort");
			if([kvpairs[@"oscSendHost"] isEqualToString:@""]) {
				kvpairs[@"oscSendHost"] = @"localhost"; // default
			}
		}
		if(DICT_EXISTS(dict, @"receive")) {
			READ_PORT(dict[@"receive"], @"port", @"oscListenPort");
			READ_STRING(dict[@"receive"], @"group", @"oscListenGroup");
		}
	}
	if(DICT_EXISTS(config, @"midi")) {
		dict = config[@"midi"];
		READ_BOOL(dict, @"enabled", @"midiEnabled");
		READ_BOOL(dict, @"virtual", @"virtualMidiEnabled");
		READ_BOOL(dict, @"network", @"networkMidiEnabled");
		READ_BOOL(dict, @"multimode", @"multiMidiDeviceMode");
	}
	if(DICT_EXISTS(config, @"behavior")) {
		dict = config[@"behavior"];
		READ_BOOL(dict, @"nolockscreen", @"lockScreenDisabled");
		READ_BOOL(dict, @"background", @"runsInBackground");
		READ_BOOL(dict, @"console", @"logTextView");
	}
	if(DICT_EXISTS(config, @"startup")) {
		dict = config[@"startup"];
		if(STRING_EXISTS(dict, @"path")) {
			NSString *s = [Util.documentsPath stringByAppendingPathComponent:dict[@"path"]];
			if(s) {
				NSLog(@"AppDelegate: startup path %@", s);
				// wait a second to give the rest of the ui time to load
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					if(![self openPath:s]) {
						NSLog(@"AppDelegate: couldn't open path: %@", s);
					}
				});
			}
		}
	}
	#ifdef DEBUG_CONFIG
		NSLog(@"AppDelegate: config kv pairs");
		for(NSString *key in pairs.allKeys) {
			NSLog(@"AppDelegate:   %@: %@", key, pairs[key]);
		}
	#else
		[NSUserDefaults.standardUserDefaults setValuesForKeysWithDictionary:kvpairs];
	#endif
}

#pragma mark Util

- (void)copyLibDirectory {
	NSError *error;
	if(![self copyResourcePatchDirectoryToDocuments:@"lib" error:error]) {
		[[UIAlertController alertControllerWithTitle:@"Couldn't copy lib folder"
		                                     message:error.localizedDescription
		                           cancelButtonTitle:@"Ok"] show];
	}
}

- (void)copySamplesDirectory {
	NSError *error;
	if(![self copyResourcePatchDirectoryToDocuments:@"samples" error:error]) {
		[[UIAlertController alertControllerWithTitle:@"Couldn't copy samples folder"
		                                     message:error.localizedDescription
		                           cancelButtonTitle:@"Ok"] show];
	}
}

- (void)copyTestsDirectory {
	NSError *error;
	if(![self copyResourcePatchDirectoryToDocuments:@"tests" error:error]) {
		[[UIAlertController alertControllerWithTitle:@"Couldn't copy tests folder"
		                                     message:error.localizedDescription
		                           cancelButtonTitle:@"Ok"] show];
	}
}

#pragma mark UIGuidedAccessRestrictionDelegate

// add custom restrictions which appear as switches in the Guided Access Options view
// ref: https://developer.apple.com/documentation/uikit/uiguidedaccessrestrictiondelegate?language=objc
// ref: https://developer.apple.com/library/archive/samplecode/sc2216/Listings/CustomContentAccessibility_APLAppDelegate_m.html

static NSString *const PdPartyBackButtonRestrictionIdentifier = @"com.danomatika.CustomContentAccessibility.BackButtonRestrictionIdentifier";
static NSString *const PdPartyControlsButtonRestrictionIdentifier = @"com.danomatika.CustomContentAccessibility.ControlsButtonRestrictionIdentifier";

// custom restrictions
- (NSArray *)guidedAccessRestrictionIdentifiers {
	return @[PdPartyBackButtonRestrictionIdentifier, PdPartyControlsButtonRestrictionIdentifier];
}

// title
- (NSString *)textForGuidedAccessRestrictionWithIdentifier:(NSString *)restrictionIdentifier {
	if([restrictionIdentifier isEqualToString:PdPartyBackButtonRestrictionIdentifier]) {
		return NSLocalizedString(@"Back Button", nil);
	}
	else if([restrictionIdentifier isEqualToString:PdPartyControlsButtonRestrictionIdentifier]) {
		return NSLocalizedString(@"Controls Button", nil);
	}
	return nil;
}

// detail text description
- (NSString *)detailTextForGuidedAccessRestrictionWithIdentifier:(NSString *)restrictionIdentifier {
	if([restrictionIdentifier isEqualToString:PdPartyBackButtonRestrictionIdentifier]) {
		return NSLocalizedString(@"Return to browser from current PdParty scene", nil);
	}
	else if([restrictionIdentifier isEqualToString:PdPartyControlsButtonRestrictionIdentifier]) {
		return NSLocalizedString(@"Open PdParty controls popover", nil);
	}
	return nil;
}

// restriction state change event handler
- (void)guidedAccessRestrictionWithIdentifier:(NSString *)restrictionIdentifier didChangeState:(UIGuidedAccessRestrictionState)newRestrictionState {
	BOOL allowed = (newRestrictionState == UIGuidedAccessRestrictionStateAllow);
	if([restrictionIdentifier isEqualToString:PdPartyBackButtonRestrictionIdentifier]) {
		self.patchViewController.hidesBackButton = !allowed;
	}
	else if([restrictionIdentifier isEqualToString:PdPartyControlsButtonRestrictionIdentifier]) {
		self.patchViewController.hidesControlsButton = !allowed;
	}
	else {return;}
	LogVerbose(@"%@ %@", restrictionIdentifier, (allowed ? @"allow" : @"deny"));
}

#pragma mark Overridden Getters / Setters

// update button state when view is loaded on iPhone
- (void)setPatchViewController:(PatchViewController *)patchViewController {
	_patchViewController = patchViewController;
	self.patchViewController.hidesBackButton =
		(UIGuidedAccessRestrictionStateForIdentifier(PdPartyBackButtonRestrictionIdentifier) == UIGuidedAccessRestrictionStateDeny);
	self.patchViewController.hidesControlsButton =
		(UIGuidedAccessRestrictionStateForIdentifier(PdPartyControlsButtonRestrictionIdentifier) == UIGuidedAccessRestrictionStateDeny);
}

- (BOOL)isPatchViewVisible {
	return self.patchViewController && self.patchViewController.isViewLoaded && self.patchViewController.view.window;
}

- (void)setLockScreenDisabled:(BOOL)lockScreenDisabled {
	_lockScreenDisabled = lockScreenDisabled;
	[UIApplication.sharedApplication setIdleTimerDisabled:lockScreenDisabled];
	[NSUserDefaults.standardUserDefaults setBool:lockScreenDisabled forKey:@"lockScreenDisabled"];
}

- (void)setRunsInBackground:(BOOL)runsInBackground {
	_runsInBackground = runsInBackground;
	[NSUserDefaults.standardUserDefaults setBool:runsInBackground forKey:@"runsInBackground"];
}

#pragma mark Private

- (BOOL)copyResourcePatchDirectoryToDocuments:(NSString *)dirPath error:(NSError *)error {
	LogVerbose(@"AppDelegate: copying %@ to Documents", dirPath);
	
	// create dest folder if it doesn't exist
	NSString *destPath = [Util.documentsPath stringByAppendingPathComponent:dirPath];
	if(![NSFileManager.defaultManager fileExistsAtPath:destPath]) {
		if(![NSFileManager.defaultManager createDirectoryAtPath:destPath withIntermediateDirectories:NO attributes:NULL error:&error]) {
			LogError(@"AppDelegate: couldn't create %@, error: %@", destPath, error.localizedDescription);
			return NO;
		}
	}
	
	// patch folder resources are in patches/*
	NSString *srcPath = [[Util.bundlePath stringByAppendingPathComponent:@"patches"] stringByAppendingPathComponent:dirPath];
	
	// recursively copy all items within src into dest, this way we don't lose any other files or folders added by the user
	return [Util copyContentsOfDirectory:srcPath toDirectory:destPath error:error];
}

@end
