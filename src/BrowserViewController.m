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
#import "BrowserViewController.h"

#import "AppDelegate.h"
#import "PatchViewController.h"
#import "Log.h"
#import "Unzip.h"
#import "Util.h"

@interface BrowserViewController () {
	/// temp variables required for segues on iPhone since PatchViewController
	/// may not exist yet when opening first scene
	NSString *selectedPatch; ///< maybe subpatch in the case of Rj Scenes, etc
	NSString *selectedSceneType;
}

/// run the given scene in the PatchViewController
- (void)runScene:(NSString *)fullpath withSceneType:(NSString *)sceneType;

/// called when a patch is selected, return NO if the path was not handled
- (BOOL)selectFile:(NSString *)path; ///< assumes full path
- (BOOL)selectDirectory:(NSString *)path; ///< assumes full path

@end

@implementation BrowserViewController

- (void)viewDidLoad {
	// Do any additional setup after loading the view, typically from a nib.
	[super viewDidLoad];

	// set instance pointer
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.browserViewController = self;

	self.delegate = self;
	self.canAddFiles = NO;
	self.title = self.navigationItem.title; // grab title from storyboard
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// make sure initial layer is loaded when showing,
	// do this here instead of viewDidLoad: as this might have
	// been manually loaded outside of a segue
	if(!self.directory) {
		[self loadDocumentsDirectory];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if([[segue identifier] isEqualToString:@"runScene"]) { // load the selected patch
		// iPhone opens here
		[[segue destinationViewController] openScene:selectedPatch withType:selectedSceneType];
	}
}

- (BOOL)loadDocumentsDirectory {
	return [self loadDirectory:Util.documentsPath];
}

- (BOOL)openPath:(NSString *)path {
	BOOL isDir;
	if([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
		// open to parent directory
		[self clearDirectory];
		if([self loadDirectory:path.stringByDeletingLastPathComponent relativeTo:Util.documentsPath]) {
			// try opening
			if(isDir) {
				if([self selectDirectory:path]) {
					return YES;
				}
				// load regular directory
				[self clearDirectory];
				return [self loadDirectory:path relativeTo:Util.documentsPath];
			}
			else {
				if([self selectDirectory:path.stringByDeletingLastPathComponent]) {
					return YES; // try to open as scene
				}
				return [self selectFile:path]; // otherwise file
			}
		}
	}
	return NO;
}

+ (BOOL)unzipPath:(NSString *)path toDirectory:(NSString *)directory {
	BOOL failed = NO;
	NSError *error;
	NSString *filename = path.lastPathComponent;
	Unzip *zip = [[Unzip alloc] init];
	if([zip open:path]) {
		if([zip unzipTo:directory overwrite:YES]) {
			// remove existing file
			if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
				LogError(@"Browser: couldn't remove %@, error: %@",
					path, error.localizedDescription);
			}
		}
		else {
			LogError(@"Browser: couldn't open zipfile: %@", path);
			failed = YES;
		}
		[zip close];
	}
	else {
		LogError(@"Browser: couldn't unzip %@ to %@", path, directory.lastPathComponent);
		failed = YES;
	}
	if(failed) {
		NSString *message = [NSString stringWithFormat:@"Could not decompress %@ to %@",
			filename, directory.lastPathComponent];
		[[UIAlertController alertControllerWithTitle:@"Unzip Failed"
		                                     message:message
		                           cancelButtonTitle:@"Ok"] show];
		return NO;
	}
	return YES;
}

#pragma mark Browser

- (UIBarButtonItem *)browsingModeRightBarItemForLayer:(BrowserLayer *)layer {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	return [app nowPlayingButton];
}

#pragma mark BrowserDelegate

- (void)browser:(Browser *)browser selectedFile:(NSString *)path {
	[self selectFile:path];
}

- (BOOL)browser:(Browser *)browser selectedDirectory:(NSString *)path {
	return ![self selectDirectory:path];
}

#pragma mark Private

- (void)runScene:(NSString *)path withSceneType:(NSString *)sceneType {
	selectedPatch = path;
	selectedSceneType = sceneType;
	if(Util.isDeviceATablet) {
		// iPad opens here
		AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
		[app.patchViewController openScene:selectedPatch withType:selectedSceneType];
	}
	else {
		[self performSegueWithIdentifier:@"runScene" sender:self];
	}
}

- (BOOL)selectFile:(NSString *)path {
	if([path.pathExtension isEqualToString:@"pd"]) { // regular patch
		[self runScene:path withSceneType:@"PatchScene"];
	}
	else if([RecordingScene isRecording:path]) { // recordings
		[self runScene:path withSceneType:@"RecordingScene"];
	}
	else if([BrowserViewController isZipFile:path]) { // unzip zipfiles
		if([BrowserViewController unzipPath:path toDirectory:self.directory]) {
			NSString *message = [NSString stringWithFormat:@"%@ unzipped to %@",
				path.lastPathComponent, self.directory.lastPathComponent];
			[[UIAlertController alertControllerWithTitle:@"Unzip Succeeded"
			                                     message:message
			                           cancelButtonTitle:@"Ok"] show];
			[self reloadDirectory];
		}
	}
	return YES;
}

- (BOOL)selectDirectory:(NSString *)path {
	if([DroidScene isDroidPartyDirectory:path]) {
		[self runScene:path withSceneType:@"DroidScene"];
	}
	else if([RjScene isRjDjDirectory:path]) {
		[self runScene:path withSceneType:@"RjScene"];
	}
	else if([PartyScene isPdPartyDirectory:path]) {
		[self runScene:path withSceneType:@"PartyScene"];
	}
	else { // regular dir
		return NO;
	}
	return YES;
}

@end
