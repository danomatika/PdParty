/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */

#import "FileBrowserLayer.h"
#include "FileBrowser.h"

#import "Log.h"
#import "Util.h"

// make life easier here ...
#import "UIActionSheet+Blocks.h"

static FileBrowserLayer *s_moveRoot; //< browser layer that invoked a move edit
static NSMutableArray *s_movePaths; //< paths to move

@interface FileBrowserLayer () {
	// for maintaining the scroll pos when navigating back,
	// from http://make-smart-iphone-apps.blogspot.com/2011/04/how-to-maintain-uitableview-scrolled.html
	CGPoint scrollPos;
	BOOL scrollPosSet;
}
// readwrite overrides
@property (readwrite, nonatomic) NSString *directory;
@property (readwrite, nonatomic) NSMutableArray *paths;
@end

@implementation FileBrowserLayer

@dynamic title;

- (id)init {
	self = [super init];
	if(self) {
		[self setup];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		[self setup];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		[self setup];
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if(self) {
		[self setup];
    }
    return self;
}

- (void)setup {
	scrollPos = CGPointZero;
	scrollPosSet = NO;
	self.paths = [[NSMutableArray alloc] init];
	_mode = FileBrowserModeBrowse;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// make sure the cell class is known
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"FileBrowserCell"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// (re)generate navigation items
	self.mode = _mode;
	
	// make sure tool bar is visible
	if(self.toolbarItems.count > 0) {
		self.navigationController.toolbarHidden = NO;
	}

	// reset to saved pos
	if(scrollPosSet) {
		[self.tableView setContentOffset:scrollPos animated:NO];
		scrollPosSet = NO;
	}
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
			if([self shouldAddPath:fullPath isDir:[Util isDirectory:fullPath]]) {
				[self.paths addObject:fullPath];
			}
		}
	}
	self.directory = dirPath;
	[self.tableView reloadData];
}

- (void)reloadDirectory {
	[self.paths removeAllObjects];
	[self loadDirectory:self.directory];
	[self.tableView reloadData];
}

- (void)clearDirectory {
	[self.paths removeAllObjects];
	[self.tableView reloadData];
	self.directory = nil;
}

#pragma mark Subclassing

- (UIBarButtonItem *)browsingModeRightBarItem {
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
}

- (BOOL)shouldAddPath:(NSString *)path isDir:(BOOL)isDir {
	return YES;
}

- (void)styleCell:(UITableViewCell *)cell forPath:(NSString *)path isDir:(BOOL)isDir {
	if(isDir) {
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		cell.textLabel.text = [path lastPathComponent];
	}
	else { // files
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		cell.textLabel.text = [path lastPathComponent];
	}
}

#pragma mark Overridden Getters/Setters

// navigationItem is created on demand and used by the nav controller, whether
// it's currently set or added later on, so this works
- (void)setMode:(FileBrowserMode)mode {
	_mode = mode;
	NSMutableArray *barButtons = [[NSMutableArray alloc] init];
	switch(mode) {
		case FileBrowserModeBrowse:
			if(self.root.canAddFiles || self.root.canAddDirectories) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
									   target:self
									   action:@selector(addButtonPressed)]];
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
									   target:nil
									   action:nil]];
			}
			if(self.root.directoriesOnly && self.root.canSelectDirectories) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithTitle:@"Choose Folder"
									   style:UIBarButtonItemStylePlain
									   target:self
									   action:@selector(chooseFolderButtonPressed)]];
			}
			if(self.root.showEditButton) {
				[barButtons addObject:[[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
								   target:nil
								   action:nil]];
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
									   target:self
									   action:@selector(editButtonPressed)]];
			}
			self.toolbarItems = barButtons;
			self.navigationItem.rightBarButtonItem = [self browsingModeRightBarItem];
			[self setEditing:NO animated:YES];
			break;
		case FileBrowserModeEdit:
			if(self.root.showMoveButton) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									  initWithTitle:@"Move"
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(moveButtonPressed)]];
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
									   target:nil
									   action:nil]];
			}
			[barButtons addObject:[[UIBarButtonItem alloc]
								   initWithTitle:@"Rename"
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(renameButtonPressed)]];
			[barButtons addObject:[[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
								   target:nil
								   action:nil]];
			[barButtons addObject:[[UIBarButtonItem alloc]
								   initWithTitle:@"Delete"
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(deleteButtonPressed)]];
			self.toolbarItems = barButtons;
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
													  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													  target:self
													  action:@selector(doneButtonPressed)];
			[self setEditing:YES animated:YES];
			break;
		case FileBrowserModeMove:
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithTitle:@"New Folder"
								  style:UIBarButtonItemStylePlain
								  target:self
								  action:@selector(newFolderButtonPressed)]];
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
								  target:nil
								  action:nil]];
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithTitle:@"Move Here"
								  style:UIBarButtonItemStylePlain
								  target:self
								  action:@selector(moveHereButtonPressed)]];
			self.toolbarItems = barButtons;
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
													  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													  target:self
													  action:@selector(doneButtonPressed)];
			[self setEditing:NO animated:YES];
			break;
	}
}

// custom back button with current dir to show on layer above
- (void)setDirectory:(NSString *)directory {
	_directory = directory;
	if(_directory) {
		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:[_directory lastPathComponent]
												 style:UIBarButtonItemStylePlain
												 target:self
												 action:@selector(backButtonPressed:)];
	}
	else {
		self.navigationItem.backBarButtonItem = nil;
	}
}

// nav bar title is generated based on this value
- (NSString *)title {
	return (super.title ? super.title : [self.directory lastPathComponent]);
}

// when not editing, disable multi selection to enable swipe to Delete
- (void)setEditing:(BOOL)editing {
	if(self.isEditing == editing) return;
	self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [super setEditing:editing];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(self.isEditing == editing) return;
	self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [super setEditing:editing animated:animated];
}

#pragma mark UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if(section == 0) {
		return self.paths.count;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileBrowserCell" forIndexPath:indexPath];
	BOOL isDir;
	NSString *path = [self.paths objectAtIndex:indexPath.row];
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(!isDir && self.root.extensions) { // restrict by extension using grey color
			if(![self.root.extensions containsObject:[path pathExtension]]) {
				cell.textLabel.textColor = [UIColor grayColor];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			else {
				cell.textLabel.textColor = [UIColor blackColor];
				cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			}
		}
		[self styleCell:cell forPath:path isDir:isDir];
	}
	else {
		DDLogWarn(@"FileBrowser: couldn't customize cell, path doesn't exist: %@", path);
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(!self.isEditing) {
		NSString *path = [self.paths objectAtIndex:indexPath.row];
		DDLogVerbose(@"FileBrowser: didSelect %ld", (long)indexPath.row);
		BOOL isDir;
		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
			if(isDir) {
				// create a new browser table view and push it on the stack
				DDLogVerbose(@"FileBrowser: now pushing folder %@", [path lastPathComponent]);
				FileBrowserLayer *browserLayer = [[FileBrowserLayer alloc] initWithStyle:self.tableView.style];
				browserLayer.root = self.root;
				browserLayer.title = self.title;
				[browserLayer loadDirectory:path];
				[self.navigationController pushViewController:browserLayer animated:YES];
			}
			else {
				if(self.root.extensions) { // restrict by extension
					if(![self.root.extensions containsObject:[path pathExtension]]) {
						[tableView deselectRowAtIndexPath:indexPath animated:NO];
						return;
					}
				}
				DDLogVerbose(@"FileBrowser: selected file %@", path);
				if([self.root.delegate respondsToSelector:@selector(fileBrowser:selectedFile:)]) {
					[self.root.delegate fileBrowser:self.root selectedFile:path];
				}
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			scrollPos = [tableView contentOffset];
			scrollPosSet = YES;
		}
		else {
			DDLogError(@"FileBrowser: can't select row in table view, file dosen't exist: %@", path);
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
		}
	}
}

// cells must be editable for mass Move & Delete actions
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(editingStyle) {
		case UITableViewCellEditingStyleDelete:
			[self.root deletePath:self.paths[indexPath.row]];
			[self.paths removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

// empty footer to hide empty cells & separators
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
     return 0.01f;
 }

// empty footer to hide empty cells & separators
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	return [[UIView alloc] init];
}

#pragma mark Browsing UI

- (void)addButtonPressed {
	DDLogVerbose(@"FileBrowser: add button pressed");
	UIActionSheet *sheet = [[UIActionSheet alloc]
							initWithTitle:nil delegate:nil
							cancelButtonTitle:@"Cancel"
							destructiveButtonTitle:nil
							otherButtonTitles:nil];
	if(self.root.canAddFiles) {
		[sheet addButtonWithTitle:@"New File"];
	}
	if(self.root.canAddDirectories) {
		[sheet addButtonWithTitle:@"New Folder"];
	}
	sheet.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
		NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
		if([button isEqualToString:@"New File"]) {
			if(self.root.canAddFiles) {
				[self.root showNewFileDialog];
			}
		}
		else if([button isEqualToString:@"New Folder"]) {
			if(self.root.canAddDirectories) {
				[self.root showNewDirectoryDialog];
			}
		}
	};
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (void)chooseFolderButtonPressed {
	DDLogVerbose(@"FileBrowser: choose folder button pressed");
	if([self.root.delegate respondsToSelector:@selector(fileBrowser:selectedDirectory:)]) {
		[self.root.delegate fileBrowser:self.root selectedDirectory:self.directory];
	}
}

- (void)editButtonPressed {
	DDLogVerbose(@"FileBrowser: edit button pressed");
	self.mode = FileBrowserModeEdit;
}

- (void)cancelButtonPressed {
	[self dismissViewControllerAnimated:YES completion:^{
		if([self.root.delegate respondsToSelector:@selector(fileBrowserCancel:)]) {
			[self.root.delegate fileBrowserCancel:self.root];
		}
	}];
}

- (void)backButtonPressed {
	DDLogVerbose(@"FileBrowser: back button pressed");
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Edit UI

- (void)moveButtonPressed {
	DDLogVerbose(@"FileBrowser: move button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	s_moveRoot = self;
	s_movePaths = [[NSMutableArray alloc] init];
	for(NSIndexPath *indexPath in indexPaths) { // save selected paths
		[s_movePaths addObject:[self.paths objectAtIndex:indexPath.row]];
	}
	FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
	browserLayer.title = @"Move";
	browserLayer.directoriesOnly = YES;
	browserLayer.mode = FileBrowserModeMove;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browserLayer];
	navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
	navigationController.toolbarHidden = NO;
	[browserLayer loadDirectory:self.directory relativeTo:[Util documentsPath]]; // load after nav controller is set
	[self presentViewController:navigationController animated:YES completion:^{
		self.mode = FileBrowserModeBrowse; // reset now so it's ready when move is done
	}];
}

- (void)renameButtonPressed {
	DDLogVerbose(@"FileBrowser: rename button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = FileBrowserModeBrowse;
	
	// rename paths at the selected indices, one by one
	NSMutableIndexSet *renamedIndices = [[NSMutableIndexSet alloc] init];
	for(NSIndexPath *indexPath in indexPaths) {
		NSString *path = [self.paths objectAtIndex:indexPath.row];
		[self.root showRenameDialogForPath:path];
	}
}

- (void)deleteButtonPressed {
	DDLogVerbose(@"FileBrowser: delete button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = FileBrowserModeBrowse;
	
	// delete paths at the selected indices
	NSMutableIndexSet *deletedIndices = [[NSMutableIndexSet alloc] init];
	for(NSIndexPath *indexPath in indexPaths) {
		if([self.root deletePath:[self.paths objectAtIndex:indexPath.row]]) {
			[deletedIndices addIndex:indexPath.row];
		}
	}
	
	// delete from model & view
	[self.tableView beginUpdates];
	[self.paths removeObjectsAtIndexes:deletedIndices]; // do this in one go, since indices may be invalidated in loop
	[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
}

- (void)doneButtonPressed {
	DDLogVerbose(@"FileBrowser: done button pressed");
	if(self.mode == FileBrowserModeMove) {
		[self dismissViewControllerAnimated:YES completion:nil];
		return;
	}
	self.mode = FileBrowserModeBrowse;
}

#pragma mark Move UI

- (void)newFolderButtonPressed {
	DDLogVerbose(@"FileBrowser: new folder button pressed");
	[self.root showNewDirectoryDialog];
}

- (void)moveHereButtonPressed {
	DDLogVerbose(@"FileBrowser: move here button pressed");
	if(!s_movePaths || s_movePaths.count < 1) {
		return;
	}
	for(NSString *path in s_movePaths) {
		[self.root movePath:path toDirectory:self.root.directory];
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[s_moveRoot reloadDirectory]; // show changes after move
	s_moveRoot = nil;
	s_movePaths = nil;
}

@end
