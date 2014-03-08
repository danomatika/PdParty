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
#import "Util.h"

@interface BrowserViewController () {
	// temp variables required for segues on iPhone since PatchViewController
	// may not exist yet when opening first scene
	NSString *selectedPatch; // maybe subpatch in the case of Rj Scenes, etc
	SceneType selectedSceneType;
	
	// for maintaining the scroll pos when navigating back,
	// from http://make-smart-iphone-apps.blogspot.com/2011/04/how-to-maintain-uitableview-scrolled.html
	CGPoint savedScrollPos;
}

@property (strong, readwrite) NSMutableArray *pathArray; // table view paths
@property (strong, readwrite) NSString *currentDir; // current directory path
@property (assign, readwrite) int currentDirLevel;

// run the given scene in the PatchViewController
- (void)runScene:(NSString *)fullpath withSceneType:(SceneType)sceneType;

// called when a patch is selected, return NO if the path was not handled
- (BOOL)didSelectDirectory:(NSString *)path; // assumes full path
- (BOOL)didSelectFile:(NSString *)path; // assumes full path

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.

	// set instance pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.browserViewController = self;

	if([Util isDeviceATablet]) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
	self.pathArray = [[NSMutableArray alloc] init];
	self.currentDirLevel = 0;
	
	// setup the docs path if this is the browser root view
	if(!self.currentDir) {
		self.currentDir = [Util documentsPath];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	// Notifies the view controller that its view is about to be added to a view hierarchy.
	[super viewWillAppear:animated];
	
	[self loadDirectory:self.currentDir];

	// reset to saved pos
	[self.tableView setContentOffset:savedScrollPos animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
	// Notifies the view controller that its view was removed from a view hierarchy.
	[super viewDidDisappear:animated];
	
	[self unloadDirectory];
}

- (void)didReceiveMemoryWarning {
    // Dispose of any resources that can be recreated.
	[super didReceiveMemoryWarning];
}

// lock orientation
- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark File Browsing

// file access error codes:
// https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html

- (void)loadDirectory:(NSString *)dirPath {

	NSError *error;

	DDLogVerbose(@"Browser: loading directory %@", dirPath);

	// search for files in the given path
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
	if(!contents) {
		DDLogError(@"Browser: couldn't load directory %@, error: %@", dirPath, error.localizedDescription);
		return;
	}
	
	// add contents to pathArray as absolute paths
	DDLogVerbose(@"Browser: found %d paths", contents.count);
	for(NSString *p in contents) {
		DDLogVerbose(@"Browser: 	%@", p);
		
		// remove Finder DS_Store garbage (created over WebDAV) and __MACOSX added to zip files
		if([p isEqualToString:@"._.DS_Store"] || [p isEqualToString:@".DS_Store"] || [p isEqualToString:@"__MACOSX"]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:[dirPath stringByAppendingPathComponent:p] error:&error]) {
				DDLogError(@"Browser: couldn't remove %@, error: %@", p, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"Browser: removed %@", p);
			}
		}
		else { // add paths
			NSString *fullPath = [dirPath stringByAppendingPathComponent:p];
			if([Util isDirectory:fullPath]) { // add directory
				[self.pathArray addObject:fullPath];
			}
			else if([[p pathExtension] isEqualToString: @"pd"]) { // add patch
				[self.pathArray addObject:fullPath];
			}
			// add recordings
			else if([RecordingScene isRecording:fullPath]) {
				[self.pathArray addObject:fullPath];
			}
			else {
				DDLogVerbose(@"Browser: dropped path: %@", p);
			}
		}
	}
	[self.tableView reloadData];
	
	self.navigationItem.title = [dirPath lastPathComponent]; // set title of back button
	self.currentDir = dirPath;
	self.navigationController.title = [dirPath lastPathComponent]; // set title of current dir
	DDLogVerbose(@"Browser: current directory now %@", dirPath);
}

- (void)reloadDirectory {
	[self unloadDirectory];
	[self loadDirectory:self.currentDir];
}

- (void)unloadDirectory {
	[self.pathArray removeAllObjects];
	[self.tableView reloadData];
}

- (BOOL)tryOpeningPath:(NSString*)path {
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(isDir) {
			if([self didSelectDirectory:path]) {
				return YES;
			}
		}
		else {
			if([self didSelectFile:path]) {
				return YES;
			}
		}
	}
	DDLogWarn(@"Browser: tried opening %@, but nothing to do", path);
	return NO;
}

#pragma mark UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return self.pathArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Customize the appearance of table view cells.
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BrowserCell" forIndexPath:indexPath];

	NSString *path = self.pathArray[indexPath.row];
	
//  BOOL isDir;
//	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
//		if(isDir) {
//			//cell.imageView =
//		}
//		else {
//			// is patch
//			//cell.imageView =
//		}
//	}
//	else {
//		DDLogError(@"Browser: couldn't select row in table view, file dosen't exist: %@", path);
//		[tableView deselectRowAtIndexPath:indexPath animated:NO];
//	}

	cell.textLabel.text = [path lastPathComponent];
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(editingStyle == UITableViewCellEditingStyleDelete) {
    
		// remove file/folder
		NSError *error;
		NSString *path = self.pathArray[indexPath.row];
		if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
				DDLogError(@"Browser: couldn't remove %@, error: %@", path, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"Browser: removed %@", path);
			}
		}
		else {
			DDLogWarn(@"Browser: couldn't remove %@, path not found", path);
		}
			
		// remove from view
		[self.pathArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
	else if(editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *path = self.pathArray[indexPath.row];
	
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(isDir) {
			if(![self didSelectDirectory:path]) {
				// create a new browser table view and push it on the stack
				UIStoryboard *board;
				if([Util isDeviceATablet]) {
					board = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
				}
				else {
					board = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
				}
				BrowserViewController *browserLayer = [board instantiateViewControllerWithIdentifier:@"BrowserViewController"];
				browserLayer.currentDir = path;
				browserLayer.currentDirLevel = self.currentDirLevel+1;
				[self.navigationController pushViewController:browserLayer animated:YES];
			}
		}
		else {
			[self didSelectFile:path];
		}
		savedScrollPos = [tableView contentOffset];
	}
	else {
		DDLogError(@"Browser: can't select row in table view, file dosen't exist: %@", path);
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	// load the selected patch
	if([[segue identifier] isEqualToString:@"runScene"]) {
		// iPhone opens here
		[[segue destinationViewController] openScene:selectedPatch withType:selectedSceneType];
    }
}

#pragma mark Private / Util

- (void)runScene:(NSString *)fullpath withSceneType:(SceneType)sceneType {
	selectedPatch = fullpath;
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

- (BOOL)didSelectDirectory:(NSString *)path {
	if([DroidScene isDroidPartyDirectory:path]) {
		[self runScene:path withSceneType:SceneTypeDroid];
	}
	else if([RjScene isRjDjDirectory:path]) {
		[self runScene:path withSceneType:SceneTypeRj];
	}
	else if([PartyScene isPdPartyDirectory:path]) {
		[self runScene:path withSceneType:SceneTypeParty];
	}
	else { // regular dir
		return NO;
	}
	return YES;
}

- (BOOL)didSelectFile:(NSString *)path {
	// regular patch
	if([[path pathExtension] isEqualToString:@"pd"]) {
		[self runScene:path withSceneType:SceneTypePatch];
	}
	else if([RecordingScene isRecording:path]) {
		[self runScene:path withSceneType:SceneTypeRecording];
	}
	return YES;
}

@end
