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

#import "ZipArchive.h"

#import "AppDelegate.h"
#import "PatchViewController.h"
#import "Log.h"
#import "Util.h"

@interface BrowserViewController () {
	/// temp variables required for segues on iPhone since PatchViewController
	/// may not exist yet when opening first scene
	NSString *selectedPatch; //< maybe subpatch in the case of Rj Scenes, etc
	NSString *selectedSceneType;
}

/// run the given scene in the PatchViewController
- (void)runScene:(NSString *)fullpath withSceneType:(NSString *)sceneType;

/// called when a patch is selected, return NO if the path was not handled
- (BOOL)selectFile:(NSString *)path; //< assumes full path
- (BOOL)selectDirectory:(NSString *)path; //< assumes full path

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
	[super viewDidLoad];

	// set instance pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.browserViewController = self;

	self.delegate = self;
	self.canAddFiles = NO;
	self.title = self.navigationItem.title; // grab title from storyboard
	[self loadDirectory:[Util documentsPath]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if([[segue identifier] isEqualToString:@"runScene"]) { // load the selected patch
		// iPhone opens here
		[[segue destinationViewController] openScene:selectedPatch withType:selectedSceneType];
	}
}

- (BOOL)tryOpeningPath:(NSString*)path {
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(isDir) {
			if([self selectDirectory:path]) {
				return YES;
			}
		}
		else {
			if([self selectFile:path]) {
				return YES;
			}
		}
	}
	DDLogWarn(@"Browser: tried opening %@, but nothing to do", path);
	return NO;
}

#pragma mark Browser

- (UIBarButtonItem *)browsingModeRightBarItemForLayer:(BrowserLayer *)layer {
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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
	if([Util isDeviceATablet]) {
		// iPad opens here
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		[app.patchViewController openScene:selectedPatch withType:selectedSceneType];
	}
	else {
		[self performSegueWithIdentifier:@"runScene" sender:self];
	}
}

- (BOOL)selectFile:(NSString *)path {
	if([[path pathExtension] isEqualToString:@"pd"]) { // regular patch
		[self runScene:path withSceneType:@"PatchScene"];
	}
	else if([RecordingScene isRecording:path]) { // recordings
		[self runScene:path withSceneType:@"RecordingScene"];
	}
	else if([BrowserViewController isZipFile:path]) { // unzip zipfiles
		NSError *error;
		NSString *filename = [path lastPathComponent];
		ZipArchive *zip = [[ZipArchive alloc] init];
		if([zip UnzipOpenFile:path]) {
			if(![zip UnzipFileTo:[Util documentsPath] overWrite:YES]) {
				DDLogError(@"Browser: couldn't open zipfile: %@", path);
				UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle: @"Unzip Failed"
                                      message: [NSString stringWithFormat:@"Could not decompress %@", filename]
                                      delegate: nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
				[alert show];
			}
			[zip UnzipCloseFile];
		}
		else {
			DDLogError(@"Browser: couldn't unzip %@", path);
			UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle: @"Unzip Failed"
                                      message: [NSString stringWithFormat:@"Could not decompress %@", filename]
                                      delegate: nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
			[alert show];
			return NO;
		}
		if(![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) { // remove existing file
			DDLogError(@"Browser: couldn't remove %@, error: %@", path, error.localizedDescription);
		}
		DDLogVerbose(@"Browser: unzipped %@", filename);
		UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle: @"Unzip Succeeded"
								  message: [NSString stringWithFormat:@"%@ unzipped", filename]
								  delegate: nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil];
		[alert show];
		[self reloadDirectory];
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
