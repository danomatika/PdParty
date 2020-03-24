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
#import "BrowserLayer.h"
#import "Browser.h"

#import "Log.h"
#import "Util.h"

// make life easier here ...
#import "UIActionSheet+Blocks.h"

#pragma mark - BrowserLayerCell

// custom cell so default init sets subtitle style
@interface BrowserLayerCell : UITableViewCell
@end
@implementation BrowserLayerCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	return self;
}
@end

#pragma mark - BrowserLayer

static BrowserLayer *s_moveRoot; //< browser layer that invoked a move edit
static NSMutableArray *s_movePaths; //< paths to move

@interface BrowserLayer () {
	// for maintaining the scroll pos when navigating back,
	// from http://make-smart-iphone-apps.blogspot.com/2011/04/how-to-maintain-uitableview-scrolled.html
	CGPoint scrollPos;
	BOOL scrollPosSet;
	NSMutableSet *nonSelectableRows;
}
@end

@implementation BrowserLayer

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// make sure the cell class is known
	[self.tableView registerClass:BrowserLayerCell.class forCellReuseIdentifier:@"BrowserLayerCell"];
	
	// set size in iPad popup
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		self.clearsSelectionOnViewWillAppear = NO;
		self.preferredContentSize = CGSizeMake(320.0, 600.0);
	}
}

- (void)viewWillAppear:(BOOL)animated {
	
	// (re)generate navigation items
	self.mode = _mode;
	
	// make sure tool bar is visible
	if(self.toolbarItems.count > 0) {
		self.navigationController.toolbarHidden = NO;
	}
	else {
		self.navigationController.toolbarHidden = YES;
	}
	
	// reload if required
	if(_directory && _paths.count == 0) {
		[self reloadDirectory];
	}

	// reset to saved pos
	if(scrollPosSet) {
		[self.tableView setContentOffset:scrollPos animated:NO];
		scrollPosSet = NO;
	}
	
	[super viewWillAppear:animated];
}

// make sure toolbar from browser does not carry over on iPhone
- (void)viewWillDisappear:(BOOL)animated {
	self.navigationController.toolbarHidden = YES;
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	// clear data when not in view
	[self unloadDirectory];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return [self.root supportedInterfaceOrientations];
}

#pragma mark Location

// file access error codes:
// https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html

- (BOOL)loadDirectory:(NSString *)dirPath {
	NSError *error;
	DDLogVerbose(@"Browser: loading directory %@", dirPath);

	// search for files in the given path and sort
	NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirPath error:&error];
	if(!contents) {
		DDLogError(@"Browser: couldn't load directory %@, error: %@", dirPath, error.localizedDescription);
		return NO;
	}
	contents = [contents sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
	
	// add contents to pathArray as absolute paths
	DDLogVerbose(@"Browser: found %d paths", (int) contents.count);
	for(NSString *p in contents) {
		DDLogVerbose(@"Browser: 	%@", p);
		NSString *fullPath = [dirPath stringByAppendingPathComponent:p];
		if([self.root.dataDelegate browser:self.root shouldAddPath:fullPath isDir:[Util isDirectory:fullPath]]) {
			[_paths addObject:fullPath];
		}
	}
	_directory = dirPath;
	[self.tableView reloadData];
	// custom back button with current dir to show on layer above
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:_directory.lastPathComponent
												 style:UIBarButtonItemStylePlain
												 target:self
												 action:@selector(backButtonPressed)];
	self.navigationItem.title = _directory.lastPathComponent;
	return YES;
}

- (void)reloadDirectory {
	[_paths removeAllObjects];
	nonSelectableRows = nil;
	[self loadDirectory:_directory];
	[self.tableView reloadData];
}

- (void)unloadDirectory {
	[_paths removeAllObjects];
	nonSelectableRows = nil;
	[self.tableView reloadData];
}

- (void)clearDirectory {
	[_paths removeAllObjects];
	nonSelectableRows = nil;
	[self.tableView reloadData];
	_directory = nil;
	self.navigationItem.backBarButtonItem = nil;
}

#pragma mark Subclassing

- (void)setup {
	scrollPos = CGPointZero;
	scrollPosSet = NO;
	nonSelectableRows = nil;
	_paths = [[NSMutableArray alloc] init];
	_mode = BrowserModeBrowse;
}

#pragma mark Overridden Getters/Setters

// navigationItem is created on demand and used by the nav controller, whether
// it's currently set or added later on, so this works
- (void)setMode:(BrowserMode)mode {
	_mode = mode;
	NSMutableArray *barButtons = [[NSMutableArray alloc] init];
	switch(mode) {
		case BrowserModeBrowse:
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
			self.navigationItem.rightBarButtonItem = [self.root browsingModeRightBarItemForLayer:self];
			[self setEditing:NO animated:YES];
			break;
		case BrowserModeEdit:
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
		case BrowserModeMove:
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
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

// nav bar title is generated based on this value
- (NSString *)title {
	return (super.title ? super.title : _directory.lastPathComponent);
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
		return _paths.count;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BrowserLayerCell" forIndexPath:indexPath];
    if(!cell) {
		cell = [[BrowserLayerCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:@"BrowserLayerCell"];
	}
	BOOL isDir;
	NSString *path = _paths[indexPath.row];
	if([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
		BOOL isSelectable = YES;
		if(isDir) {
			isSelectable = [self.root.dataDelegate browser:self.root isPathSelectable:path isDir:isDir];
		}
		else { // files
			if(self.root.mode == BrowserModeMove) { // restrict to dirs when moving
				isSelectable = NO;
			}
			else {
				if(self.root.extensions) { // restrict by extension using grey color
					isSelectable = [self.root pathHasAllowedExtension:path];
				}
				isSelectable = isSelectable && [self.root.dataDelegate browser:self.root isPathSelectable:path isDir:isDir];
			}
		}
		if(!isSelectable) { // save set of non selectable rows
			if(!nonSelectableRows) {
				nonSelectableRows = [[NSMutableSet alloc] init];
			}
			[nonSelectableRows addObject:[NSNumber numberWithInteger:indexPath.row]];
		}
		
		[self.root.dataDelegate browser:self.root styleCell:cell forPath:path isDir:isDir isSelectable:isSelectable];
	}
	else {
		DDLogWarn(@"Browser: couldn't customize cell, path doesn't exist: %@", path);
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(!self.isEditing) {
		NSString *path = _paths[indexPath.row];
		BOOL isDir;
		if([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
			if([nonSelectableRows containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
				return;
			}
			if(isDir) {
				DDLogVerbose(@"Browser: now selected dir %@", path.lastPathComponent);
				BOOL pushLayer = YES;
				if([self.root.delegate respondsToSelector:@selector(browser:selectedDirectory:)]) {
					pushLayer = [self.root.delegate browser:self.root selectedDirectory:path];
				}
				if(pushLayer) {
					// create a new browser table view and push it on the stack
					BrowserLayer *browserLayer = [[BrowserLayer alloc] initWithStyle:self.tableView.style];
					browserLayer.root = self.root;
					browserLayer.title = self.title;
					browserLayer.mode = self.mode;
					[browserLayer loadDirectory:path];
					[self.navigationController pushViewController:browserLayer animated:YES];
				}
			}
			else {
				DDLogVerbose(@"Browser: selected file %@", path.lastPathComponent);
				if([self.root.delegate respondsToSelector:@selector(browser:selectedFile:)]) {
					[self.root.delegate browser:self.root selectedFile:path];
				}
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			scrollPos = [tableView contentOffset];
			scrollPosSet = YES;
		}
		else {
			DDLogError(@"Browser: can't select row in table view, file dosen't exist: %@", path);
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
			[self.root deletePath:_paths[indexPath.row]];
			[_paths removeObjectAtIndex:indexPath.row];
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

// https://ajnaware.wordpress.com/2011/02/26/dynamically-adding-uiactionsheet-buttons
- (void)addButtonPressed {
	DDLogVerbose(@"Browser: add button pressed");
	// show action sheet
	if(self.root.canAddFiles && self.root.canAddDirectories) {
		UIActionSheet *sheet = [[UIActionSheet alloc]
								initWithTitle:nil delegate:nil
								cancelButtonTitle:nil
								destructiveButtonTitle:nil
								otherButtonTitles:nil];
		if(self.root.canAddFiles) {
			[sheet addButtonWithTitle:@"New File"];
		}
		if(self.root.canAddDirectories) {
			[sheet addButtonWithTitle:@"New Folder"];
		}
		// make sure Cancel is on bottom
		[sheet setCancelButtonIndex:[sheet addButtonWithTitle:@"Cancel"]];
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
	else { // show dialog directly, no action sheet
		if(self.root.canAddFiles) {
			[self.root showNewFileDialog];
		}
		else if(self.root.canAddDirectories) {
			[self.root showNewDirectoryDialog];
		}
	}
}

- (void)chooseFolderButtonPressed {
	DDLogVerbose(@"Browser: choose folder button pressed");
	if([self.root.delegate respondsToSelector:@selector(browser:selectedDirectory:)]) {
		[self.root.delegate browser:self.root selectedDirectory:_directory];
	}
}

- (void)editButtonPressed {
	DDLogVerbose(@"Browser: edit button pressed");
	self.mode = BrowserModeEdit;
}

- (void)cancelButtonPressed {
	[self dismissViewControllerAnimated:YES completion:^{
		if([self.root.delegate respondsToSelector:@selector(browserCancel:)]) {
			[self.root.delegate browserCancel:self.root];
		}
	}];
}

- (void)backButtonPressed {
	DDLogVerbose(@"Browser: back button pressed");
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Edit UI

- (void)moveButtonPressed {
	DDLogVerbose(@"Browser: move button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	s_moveRoot = self;
	s_movePaths = [[NSMutableArray alloc] init];
	for(NSIndexPath *indexPath in indexPaths) { // save selected paths
		[s_movePaths addObject:_paths[indexPath.row]];
	}
	Browser *browserLayer = [self.root newBrowser]; // use subclass
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browserLayer];
	browserLayer.title = [NSString stringWithFormat:@"Moving %lu item%@", (unsigned long)s_movePaths.count, (s_movePaths.count > 1 ? @"s" : @"")];
	browserLayer.directoriesOnly = YES;
	browserLayer.mode = BrowserModeMove;
	navigationController.toolbarHidden = NO;
	navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	navigationController.modalInPopover = YES;
	[browserLayer loadDirectory:_directory relativeTo:Util.documentsPath]; // load after nav controller is set
	[self.navigationController presentViewController:navigationController animated:YES completion:^{
		self.mode = BrowserModeBrowse; // reset now so it's ready when move is done
	}];
}

- (void)renameButtonPressed {
	DDLogVerbose(@"Browser: rename button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = BrowserModeBrowse;
	
	// rename paths at the selected indices, one by one
	for(NSIndexPath *indexPath in indexPaths) {
		NSString *path = _paths[indexPath.row];
		[self.root showRenameDialogForPath:path];
	}
}

- (void)deleteButtonPressed {
	DDLogVerbose(@"Browser: delete button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = BrowserModeBrowse;
	
	// delete paths at the selected indices
	NSMutableIndexSet *deletedIndices = [[NSMutableIndexSet alloc] init];
	for(NSIndexPath *indexPath in indexPaths) {
		if([self.root deletePath:_paths[indexPath.row]]) {
			[deletedIndices addIndex:indexPath.row];
		}
	}
	
	// delete from model & view
	[self.tableView beginUpdates];
	[_paths removeObjectsAtIndexes:deletedIndices]; // do this in one go, since indices may be invalidated in loop
	[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
}

- (void)doneButtonPressed {
	DDLogVerbose(@"Browser: done button pressed");
	if(self.mode == BrowserModeMove) {
		[self dismissViewControllerAnimated:YES completion:nil];
		return;
	}
	self.mode = BrowserModeBrowse;
}

#pragma mark Move UI

- (void)newFolderButtonPressed {
	DDLogVerbose(@"Browser: new folder button pressed");
	[self.root showNewDirectoryDialog];
}

- (void)moveHereButtonPressed {
	DDLogVerbose(@"Browser: move here button pressed");
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
