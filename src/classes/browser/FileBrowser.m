/*
 * Copyright (c) 2014 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */

#import "FileBrowser.h"

//#import "AppDelegate.h"
#import "Log.h"
#import "Util.h"
#import "FileBrowserCell.h"

// make life easier here ...
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import <objc/runtime.h>

static const void *FileBrowserDidCreateFileBlockKey = &FileBrowserDidCreateFileBlockKey;
static const void *FileBrowserDidCreateFolderBlockKey = &FileBrowserDidCreateFolderBlockKey;
static const void *FileBrowserDidRenameBlockKey = &FileBrowserDidRenameBlockKey;
static const void *FileBrowserDidMoveBlockKey = &FileBrowserDidMoveBlockKey;
static const void *FileBrowserDidDeleteBlockKey = &FileBrowserDidDeleteBlockKey;
//static const void *FileBrowserDidCancelBlockKey = &FileBrowserDidCancelBlockKey;

@interface FileBrowser () {
	
	// for maintaining the scroll pos when navigating back,
	// from http://make-smart-iphone-apps.blogspot.com/2011/04/how-to-maintain-uitableview-scrolled.html
	CGPoint savedScrollPos;
}

@property (strong, readwrite, nonatomic) NSMutableArray *pathArray; // table view paths
@property (strong, readwrite, nonatomic) NSString *currentDir; // current directory path
@property (assign, readwrite, nonatomic) int currentDirLevel;
@property (readwrite, nonatomic) FileBrowserMode mode;

// create/overwrite a file, does not check existence
- (BOOL)_createFile:(NSString *)file;

@end

@implementation FileBrowser

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if(self) {
		_mode = FileBrowserModeNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	[self.tableView registerClass:FileBrowserCell.class forCellReuseIdentifier:@"FileBrowserCell"];
	
	self.pathArray = [[NSMutableArray alloc] init];
	self.currentDirLevel = 0;
	
	// setup the docs path if this is the browser root view
	if(!self.currentDir) {
		self.currentDir = [Util documentsPath];
	}
	else {
		[self loadDirectory:self.currentDir];
	}
	
	self.navigationController.toolbarHidden = NO;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	if(_mode == FileBrowserModeNone) {
		_mode = FileBrowserModeBrowse;
	}
	self.mode = _mode;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(self.isEditing == editing) return;
	// when not editing, disable multi selection to enable swipe to Delete
	self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [super setEditing:editing animated:animated];
	self.editing = editing;
}

#pragma mark Location

// file access error codes:
// https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html

- (void)loadDirectory:(NSString *)dirPath {

	NSError *error;

	DDLogVerbose(@"FileBrowser: loading directory %@", dirPath);

	// search for files in the given path
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
	if(!contents) {
		DDLogError(@"FileBrowser: couldn't load directory %@, error: %@", dirPath, error.localizedDescription);
		return;
	}
	
	// add contents to pathArray as absolute paths
	DDLogVerbose(@"FileBrowser: found %d paths", (int) contents.count);
	for(NSString *p in contents) {
		DDLogVerbose(@"FileBrowser: 	%@", p);
		
		// remove Finder DS_Store garbage (created over WebDAV) and __MACOSX added to zip files
		if([p isEqualToString:@"._.DS_Store"] || [p isEqualToString:@".DS_Store"] || [p isEqualToString:@"__MACOSX"]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:[dirPath stringByAppendingPathComponent:p] error:&error]) {
				DDLogError(@"FileBrowser: couldn't remove %@, error: %@", p, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"FileBrowser: removed %@", p);
			}
		}
		else { // add paths
			NSString *fullPath = [dirPath stringByAppendingPathComponent:p];
			if([Util isDirectory:fullPath]) { // add directory
				[self.pathArray addObject:fullPath];
			}
			else if(!self.directoriesOnly) {
				if(self.extension) { // restrict by extension
					if([[p pathExtension] isEqualToString:self.extension]) {
						[self.pathArray addObject:fullPath];
					}
				}
				else { // allow all
					[self.pathArray addObject:fullPath];
				}
			}
//			else if([[p pathExtension] isEqualToString:@"pd"]) { // add patch
//				[self.pathArray addObject:fullPath];
//			}
//			else if([RecordingScene isRecording:fullPath]) { // add recordings
//				[self.pathArray addObject:fullPath];
//			}
//			else if([[p pathExtension] isEqualToString:@"zip"] || // add zipfiles
//					[[p pathExtension] isEqualToString:@"pdz"] ||
//					[[p pathExtension] isEqualToString:@"rjz"]) {
//				[self.pathArray addObject:fullPath];
//			}
//			else {
//				DDLogVerbose(@"FileBrowser: dropped path: %@", p);
//			}
		}
	}
	[self.tableView reloadData];
	
	self.navigationItem.title = [dirPath lastPathComponent]; // set title of back button
	self.currentDir = dirPath;
	self.navigationController.title = [dirPath lastPathComponent]; // set title of current dir
	DDLogVerbose(@"FileBrowser: current directory now %@", dirPath);
}

- (void)reloadDirectory {
	[self.pathArray removeAllObjects];
	[self loadDirectory:self.currentDir];
}

- (void)unloadDirectory {
	[self.pathArray removeAllObjects];
	[self.tableView reloadData];
}

#pragma mark Utils

- (BOOL)createFile:(NSString *)file {

	NSError *error;
	
	DDLogVerbose(@"FileBrowser: creating file: %@", file);
	
	// if this file exists, ask if it should be overwritten
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:file];
	if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?", file, [self.currentDir lastPathComponent]];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Overwrite?" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
		alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
			if(buttonIndex == 1) { // Ok
				[self _createFile:file];
			}
		};
		[alert show];
		return NO;
	}

	// create / overwrite
	return [self _createFile:file];
}

- (BOOL)createFolder:(NSString *)folder {

	NSError *error;
	
	DDLogVerbose(@"FileBrowser: creating folder: %@", folder);
	
	// create dest folder if it doesn't exist
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:folder];
	if(![[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:NO attributes:NULL error:&error]) {
			DDLogError(@"FileBrowser: couldn't create directory %@, error: %@", destPath, error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Couldn't create folder \"%@\"", folder]
															message:error.localizedDescription
														   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
	}
	else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Folder already exists"
															message:[NSString stringWithFormat:@"\"%@\" already exists in %@. Please choose a different name.", folder, [self.currentDir lastPathComponent]]
														   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		return NO;
	}

	return YES;
}

- (BOOL)renamePath:(NSString *)path to:(NSString *)newPath {
	NSError *error;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if(![[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"FileBrowser: couldn't rename %@ to %@, error: %@", path, newPath, error.localizedDescription);
			NSString *title = [NSString stringWithFormat:@"Couldn't rename %@ to \"%@\"", [path lastPathComponent], [newPath lastPathComponent]];
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
																message:error.localizedDescription
															   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"FileBrowser: renamed %@ to %@", path, newPath);
		}
	}
	else {
		DDLogWarn(@"FileBrowser: couldn't rename %@, path not found", path);
	}
	
	return YES;
}

- (BOOL)movePath:(NSString *)path toFolder:(NSString *)newFolder {

	NSError *error;
	
	NSString *newPath = [newFolder stringByAppendingPathComponent:[path lastPathComponent]];
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if(![[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"FileBrowser: couldn't move %@ to %@, error: %@", path, newPath, error.localizedDescription);
			NSString *title = [NSString stringWithFormat:@"Couldn't move %@ to \"%@\"", [path lastPathComponent], newFolder];
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
																message:error.localizedDescription
															   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"FileBrowser: moved %@ to %@", path, newFolder);
		}
	}
	else {
		DDLogWarn(@"FileBrowser: couldn't move %@, path not found", path);
	}
	
	return YES;
}

- (BOOL)deletePath:(NSString *)path {

	NSError *error;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
			DDLogError(@"FileBrowser: couldn't delete %@, error: %@", path, error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Couldn't delete %@", [path lastPathComponent]]
																message:error.localizedDescription
															   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"FileBrowser: deleted %@", path);
		}
	}
	else {
		DDLogWarn(@"FileBrowser: couldn't delete %@, path not found", path);
	}
	
	return YES;
}

#pragma mark Subclassing

//
- (UIBarButtonItem *)browsingModeRightBarItem {
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
}

#pragma mark Overridden Getters/Setters

- (void)setMode:(FileBrowserMode)mode {
	_mode = mode;
	switch(mode) {
		
		case FileBrowserModeBrowse:
			self.toolbarItems = [NSArray arrayWithObjects:
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)],
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)],
				nil];
			self.navigationItem.rightBarButtonItem = [self browsingModeRightBarItem];
			[self setEditing:NO animated:YES];
		break;
		
		case FileBrowserModeEdit:
			self.toolbarItems = [NSArray arrayWithObjects:
				[[UIBarButtonItem alloc] initWithTitle:@"Move" style:UIBarButtonItemStylePlain target:self action:@selector(moveButtonPressed)],
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
				[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(doDeleteButtonPressed)],
				nil];
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditingButtonPressed)];
			[self setEditing:YES animated:YES];
		break;
		
		case FileBrowserModeMove:
			self.toolbarItems = [NSArray arrayWithObjects:
				[[UIBarButtonItem alloc] initWithTitle:@"New Folder" style:UIBarButtonItemStylePlain target:self action:@selector(doCreateFolderButtonPressed)],
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
				[[UIBarButtonItem alloc] initWithTitle:@"Move Here" style:UIBarButtonItemStylePlain target:self action:@selector(doMoveButtonPressed)],
				nil];
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditingButtonPressed)];
			[self setEditing:NO animated:YES];
		break;
		
		case FileBrowserModeNone:
		break;
	}
}

- (FileBrowserBlock)didCreateFileBlock {
    return objc_getAssociatedObject(self, FileBrowserDidCreateFileBlockKey);
}

- (void)setDidCreateFileBlock:(FileBrowserBlock)didCreateFileBlock {
    objc_setAssociatedObject(self, FileBrowserDidCreateFileBlockKey, didCreateFileBlock, OBJC_ASSOCIATION_COPY);
}

- (FileBrowserBlock)didCreateFolderBlock {
    return objc_getAssociatedObject(self, FileBrowserDidCreateFolderBlockKey);
}

- (void)setDidCreateFolderBlock:(FileBrowserBlock)didCreateFolderBlock {
    objc_setAssociatedObject(self, FileBrowserDidCreateFolderBlockKey, didCreateFolderBlock, OBJC_ASSOCIATION_COPY);
}

- (FileBrowserBlock)didRenameBlock {
    return objc_getAssociatedObject(self, FileBrowserDidRenameBlockKey);
}

- (void)setDidRenameBlock:(FileBrowserBlock)didRenameBlock {
    objc_setAssociatedObject(self, FileBrowserDidRenameBlockKey, didRenameBlock, OBJC_ASSOCIATION_COPY);
}

- (FileBrowserBlock)didMoveBlock {
    return objc_getAssociatedObject(self, FileBrowserDidMoveBlockKey);
}

- (void)setDidMoveBlock:(FileBrowserBlock)didMoveBlock {
    objc_setAssociatedObject(self, FileBrowserDidMoveBlockKey, didMoveBlock, OBJC_ASSOCIATION_COPY);
}

- (FileBrowserBlock)didDeleteBlock {
    return objc_getAssociatedObject(self, FileBrowserDidDeleteBlockKey);
}

- (void)setDidDeleteBlock:(FileBrowserBlock)didDeleteBlock {
    objc_setAssociatedObject(self, FileBrowserDidDeleteBlockKey, didDeleteBlock, OBJC_ASSOCIATION_COPY);
}

#pragma mark Table view data source

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
	
	FileBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileBrowserCell" forIndexPath:indexPath];
	cell.delegate = self;
	cell.detailTextLabel.text = @"";

	NSString *path = self.pathArray[indexPath.row];
	
	// set file type icon
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(isDir) {
			cell.textLabel.text = [path lastPathComponent];
			
//			if([RjScene isRjDjDirectory:path]) {
//				
//				// thumbnail
//				UIImage *thumb = [RjScene thumbnailForSceneAt:path];
//				if(thumb) {
//					cell.imageView.image = thumb;
//				}
//				else {
//					cell.imageView.image = [UIImage imageNamed:@"folder"];
//				}
//				
//				// info
//				NSDictionary *info = [RjScene infoForSceneAt:path];
//				if(info) {
//					if([info objectForKey:@"name"]) {
//						cell.textLabel.text = [info objectForKey:@"name"];
//					}
//					else {
//						cell.textLabel.text = [path lastPathComponent];
//					}
//					if([info objectForKey:@"author"]) {
//						cell.detailTextLabel.text = [info objectForKey:@"author"];
//					}
//				}
//			}
//			else if([DroidScene isDroidPartyDirectory:path]) {
//				cell.imageView.image = [UIImage imageNamed:@"android"];
//				cell.textLabel.text = [path lastPathComponent];
//			}
//			else if([PartyScene isPdPartyDirectory:path]) {
//				cell.imageView.image = [UIImage imageNamed:@"pdparty"];
//				cell.textLabel.text = [path lastPathComponent];
//			}
//			else {
				cell.imageView.image = [UIImage imageNamed:@"folder"];
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
				cell.textLabel.text = [path lastPathComponent];
//			}
		}
		else { // files
//			if([BrowserViewController isZipFile:path]) {
//				cell.imageView.image = [UIImage imageNamed:@"archive"];
//			}
//			else if([RecordingScene isRecording:path]) {
//				cell.imageView.image = [UIImage imageNamed:@"audioFile"];
//			}
//			else {
				cell.imageView.image = [UIImage imageNamed:@"file"];
//			}
			[cell setAccessoryType:UITableViewCellAccessoryNone];
			cell.textLabel.text = [path lastPathComponent];
		}
	}
	else {
		DDLogWarn(@"FileBrowser: couldn't customize cell, file doesn't exist: %@", path);
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(!self.isEditing) {
	
		NSString *path = [self.pathArray objectAtIndex:indexPath.row];
		DDLogVerbose(@"FileBrowser: didSelect %d", indexPath.row);
		
		// set file type icon
		BOOL isDir;
		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
			if(isDir) {
						
					// do completion
					FileBrowserSelectionBlock completion = self.didSelectFolder;
					if(completion) {
						completion(self, path);
					}
//					else {
						// create a new browser table view and push it on the stack
						DDLogVerbose(@"FileBrowser: now pushing folder %@", [path lastPathComponent]);
						FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
						browserLayer.currentDir = path;
						browserLayer.currentDirLevel = self.currentDirLevel+1;
						browserLayer.mode = self.mode;
						[self.navigationController pushViewController:browserLayer animated:YES];
//					}
			}
			else {
				DDLogVerbose(@"FileBrowser: selected file %@", path);
				
				FileBrowserSelectionBlock completion = self.didSelectFile;
				if(completion) {
					completion(self, path);
				}
				
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			savedScrollPos = [tableView contentOffset];
		}
		else {
			DDLogError(@"FileBrowser: can't select row in table view, file dosen't exist: %@", path);
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;//self.isEditing; // disable the built in delete button since a custom one is provided in FileBrowserCell
}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//
//	if(editingStyle == UITableViewCellEditingStyleDelete) {
//    
//		// remove file/folder
//		[self deletePath:self.pathArray[indexPath.row]];
//			
//		// remove from view
//		[self.pathArray removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }
//}

// hidden footer to hide empty cells & separators
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
	view.backgroundColor = [UIColor clearColor];
	return view;
}

#pragma mark SWTableViewCellDelegate

// click event on cell right utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch(index) {
		case 1:
			DDLogVerbose(@"FileBrowser: delete utility button pressed");
			
			// remove file/folder
			[self deletePath:self.pathArray[indexPath.row]];
				
			// remove from view
			[self.pathArray removeObjectAtIndex:indexPath.row];
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case 0: {
			DDLogVerbose(@"FileBrowser: rename utility button pressed");
			
			NSString *path = [self.pathArray objectAtIndex:indexPath.row];

			NSString *title = [NSString stringWithFormat:@"Rename %@ to", [path lastPathComponent]];
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
			alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
			alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
				if(buttonIndex == 1) { // Done
					NSString *newPath = [self.currentDir stringByAppendingPathComponent:[alertView textFieldAtIndex:0].text];
					DDLogVerbose(@"FileBrowser: rename %@ to %@", [path lastPathComponent], [newPath lastPathComponent]);
					if([self renamePath:path to:newPath]) {
						
						FileBrowserBlock completion = self.didRenameBlock;
						if(completion) {
							completion(self);
						}
						
						[self reloadDirectory];
					}
				}
			};
			[alertView show];
			
			break;
		}
	}
}

// prevent multiple cells from showing utilty buttons simultaneously
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
	return YES;
}

#pragma mark Browsing UI

- (void)backButtonPressed {
	DDLogVerbose(@"FileBrowser: custom back button pressed");
	
	// create a new browser table view and push it on the stack
	FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
	browserLayer.currentDir = [self.currentDir lastPathComponent];
	browserLayer.currentDirLevel = self.currentDirLevel-1;
	browserLayer.mode = self.mode;
	[self.navigationController pushViewController:browserLayer animated:YES];
}

- (void)addButtonPressed {
	DDLogVerbose(@"FileBrowser: add pressed");
	
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"New File", @"New Folder", nil];
	
	sheet.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
		switch(buttonIndex) {
			
			// create a new file
			case 0: {
				DDLogVerbose(@"FileBrowser: new file");
				
				NSString *message;
				if(self.extension) {
					message = [NSString stringWithFormat:@"(.%@ extension will be added)", self.extension];
				}
				else {
					message = @"(include extension aka \"file.txt\")";
				}
				
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create new file" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
				alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
				alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
					if(buttonIndex == 1) { // Done
						
						NSString *file;
						if(self.extension) {
							file = [[alertView textFieldAtIndex:0].text stringByAppendingPathExtension:self.extension];
						}
						else {
							file = [alertView textFieldAtIndex:0].text;
						}
						
						DDLogVerbose(@"FileBrowser: new file: %@", file);
						if([self createFile:file]) {
							[self reloadDirectory];
						}
					}
				};
				[alertView show];
				break;
			}
			
			// create a new folder
			case 1: {
				DDLogVerbose(@"FileBrowser: new folder");
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create new folder" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
				alert.alertViewStyle = UIAlertViewStylePlainTextInput;
				alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
					if(buttonIndex == 1) { // Done
						DDLogVerbose(@"FileBrowser: new folder: %@", [alertView textFieldAtIndex:0].text);
						if([self createFolder:[alertView textFieldAtIndex:0].text]) {
							[self reloadDirectory];
						}
					}
				};
				[alert show];
				break;
			}
			default:
				break;
		}
	};
	
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (void)editButtonPressed {
	DDLogVerbose(@"FileBrowser: edit button pressed");
//	[self setEditing:YES animated:YES];
//	[self editingControls];
	self.mode = FileBrowserModeEdit;
}

- (void)cancelButtonPressed {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Edit UI

- (void)moveButtonPressed {
	DDLogVerbose(@"FileBrowser: move button pressed");
	
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	
	self.mode = FileBrowserModeMove;
//	[self moveControls];
	
	
	UINavigationController *navigationController;
	
	NSArray *pathComponents = [self.currentDir pathComponents];
	int rootLevel = [[[Util documentsPath] pathComponents] count];
	int currentLevel = [pathComponents count];
	DDLogVerbose(@"FileBrowser: root %d, current %d, %@", rootLevel, currentLevel, pathComponents);
	
	NSString *dir = [Util documentsPath];
	int dirLevel = 0;
	
	for(int i = rootLevel; i < currentLevel; ++i) {
		
		NSLog(@"%d %@", dirLevel, dir);
		
		FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
		browserLayer.currentDir = dir;
		browserLayer.currentDirLevel = dirLevel;
		browserLayer.directoriesOnly = YES;
		browserLayer.mode = FileBrowserModeMove;
		
		browserLayer.didMoveBlock = ^(FileBrowser *browser) {//, NSString *selection) {
			DDLogVerbose(@"FileBrowser: didMove called");
			
			// move folders
			for(NSIndexPath *indexPath in indexPaths) {
				NSLog(@" %@", [self.pathArray objectAtIndex:indexPath.row]);
				[self movePath:[self.pathArray objectAtIndex:indexPath.row] toFolder:browser.currentDir];
			}
			
			[navigationController dismissViewControllerAnimated:YES completion:nil];
			self.mode = FileBrowserModeBrowse;
			[self reloadDirectory];
		};
		
//		browserLayer.didMoveBlock = ^(FileBrowser *browser) {
//			DDLogVerbose(@"FileBrowser: didMoveBlock called");
//			
//			//
//			for(NSIndexPath *indexPath in indexPaths) {
//				NSLog(@" %@", [self.pathArray objectAtIndex:indexPath.row]);
//				[self movePath:[self.pathArray objectAtIndex:indexPath.row] toFolder:browser.currentDir];
//			}
//			[navigationController dismissViewControllerAnimated:YES completion:nil];
//		};
	
		if(dirLevel == 0) {
			navigationController = [[UINavigationController alloc] initWithRootViewController:browserLayer];
			[self presentViewController:navigationController animated:YES completion:nil];
		}
		else {
			[navigationController pushViewController:browserLayer animated:NO];
		}
		
		dirLevel = dirLevel+1;
		dir = [dir stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
	}
}

- (void)doDeleteButtonPressed {
	DDLogVerbose(@"FileBrowser: delete button pressed");
	
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	
	// delete paths at the selected indices
	NSMutableIndexSet *deletedIndices = [[NSMutableIndexSet alloc] init];
	for(NSIndexPath *indexPath in indexPaths) {
		if([self deletePath:[self.pathArray objectAtIndex:indexPath.row]]) {
			[deletedIndices addIndex:indexPath.row];
		}
	}
	
	// delete from model & view
	[self.tableView beginUpdates];
	[self.pathArray removeObjectsAtIndexes:deletedIndices]; // do this in one go, since indices may be invalidated in loop
	[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
	
	FileBrowserBlock completion = self.didDeleteBlock;
	if(completion) {
		completion(self);
	}
	
	self.mode = FileBrowserModeBrowse;
	[self setEditing:NO animated:YES];
	//[self.tableView reloadData];
	//[self reloadDirectory];
}

- (void)doneEditingButtonPressed {
	DDLogVerbose(@"FileBrowser: done edit button pressed");
//	[self setEditing:NO animated:YES];
//	[self browsingControls];
	self.mode = FileBrowserModeBrowse;
}

#pragma mark Move UI

- (void)doCreateFolderButtonPressed {
	DDLogVerbose(@"FileBrowser: do create folder pressed");
}

- (void)doMoveButtonPressed {
	DDLogVerbose(@"FileBrowser: do move pressed");
	
	if(self.didMoveBlock) {
		self.didMoveBlock(self);
	}
//	FileBrowserBlock completion = self.didMoveBlock;
//	if(completion) {
//		completion(self);
//	}
}

- (void)doneMoveButtonPressed {
	DDLogVerbose(@"FileBrowser: done move button pressed");
//	[self setEditing:NO animated:YES];
//	[self browsingControls];
	self.mode = FileBrowserModeBrowse;
}

#pragma mark Private

- (BOOL)_createFile:(NSString *)file {

	NSError *error;
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:file];

	// create/overwrite
	if(![[NSFileManager defaultManager] createFileAtPath:destPath contents:nil attributes:NULL]) {
		DDLogError(@"FileBrowser: couldn't create file %@", destPath);
		NSString *message = [NSString stringWithFormat:error.localizedDescription, file, [self.currentDir lastPathComponent]];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Couldn't create file \"%@\"", file] message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	
	return YES;
}

@end
