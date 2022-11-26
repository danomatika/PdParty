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

static BrowserLayer *s_moveRoot; ///< browser layer that invoked a move/copy edit
static NSMutableArray *s_movePaths; ///< paths to move/copy

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
	_paths = [NSMutableArray array];
	_mode = BrowserModeBrowse;
}

#pragma mark Overridden Getters/Setters

// navigationItem is created on demand and used by the nav controller, whether
// it's currently set or added later on, so this works
- (void)setMode:(BrowserMode)mode {
	_mode = mode;
	NSMutableArray *barButtons = [NSMutableArray array];
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
		case BrowserModeEdit: {
			if(self.root.showMoveButton) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithTitle:@"Move..."
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
			UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc]
											 initWithTitle:@"Delete"
											 style:UIBarButtonItemStylePlain
											 target:self
											 action:@selector(deleteButtonPressed)];
			[deleteButton setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.systemRedColor}
										forState:UIControlStateNormal];
			[barButtons addObject:deleteButton];
			self.toolbarItems = barButtons;
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
													  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													  target:self
													  action:@selector(doneButtonPressed)];
			[self setEditing:YES animated:YES];
			break;
		}
		case BrowserModeMove: case BrowserModeCopy:
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
								  target:self
								  action:@selector(newFolderButtonPressed)]];
			[barButtons addObject:[[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
								  target:nil
								  action:nil]];
			if(mode == BrowserModeMove) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									  initWithTitle:@"Move Here"
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(moveHereButtonPressed)]];
			}
			else {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithTitle:@"Copy Here"
									   style:UIBarButtonItemStylePlain
									   target:self
									   action:@selector(copyHereButtonPressed)]];
			}
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
				nonSelectableRows = [NSMutableSet set];
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
			if([self.root deletePath:_paths[indexPath.row] completion:nil]) {
				[_paths removeObjectAtIndex:indexPath.row];
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			}
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
	DDLogVerbose(@"Browser: add button pressed");
	// show action sheet
	if(self.root.canAddFiles && self.root.canAddDirectories) {
		UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
																	   message:nil
																preferredStyle:UIAlertControllerStyleActionSheet];
		if(self.root.canAddFiles) {
			UIAlertAction *action = [UIAlertAction actionWithTitle:@"New File"
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * _Nonnull action) {
				if(self.root.canAddFiles) {
					[self.root showNewFileDialog];
				}
			}];
			[sheet addAction:action];
		}
		if(self.root.canAddDirectories) {
			UIAlertAction *action = [UIAlertAction actionWithTitle:@"New Folder"
															 style:UIAlertActionStyleDefault
														   handler:^(UIAlertAction * _Nonnull action) {
				if(self.root.canAddDirectories) {
					[self.root showNewDirectoryDialog];
				}
			}];
			[sheet addAction:action];
		}
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
															   style:UIAlertActionStyleCancel
															 handler:nil];
		[sheet addAction:cancelAction];
		sheet.modalPresentationStyle = UIModalPresentationPopover;
		sheet.popoverPresentationController.barButtonItem = self.toolbarItems.firstObject; // +
		[sheet show];
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
	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil
															preferredStyle:UIAlertControllerStyleActionSheet];
	UIAlertAction *moveAction = [UIAlertAction actionWithTitle:@"Move" style:UIAlertActionStyleDefault
													   handler:^(UIAlertAction * _Nonnull action) {
		s_moveRoot = self;
		[self showEditBrowserForMode:BrowserModeMove];
	}];
	UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
													   handler:^(UIAlertAction * _Nonnull action) {
		s_moveRoot = self;
		[self showEditBrowserForMode:BrowserModeCopy];
	}];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[sheet addAction:moveAction];
	[sheet addAction:copyAction];
	[sheet addAction:cancelAction];
	sheet.modalPresentationStyle = UIModalPresentationPopover;
	sheet.popoverPresentationController.barButtonItem = self.toolbarItems.firstObject; // Move...
	[sheet show];
}

- (void)renameButtonPressed {
	DDLogVerbose(@"Browser: rename button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = BrowserModeBrowse;
	NSMutableArray *paths = [NSMutableArray array];
	for(NSIndexPath *indexPath in indexPaths) {
		[paths addObject:_paths[indexPath.row]];
	}
	[self renamePathAtIndex:0 inPaths:paths];
}

- (void)deleteButtonPressed {
	DDLogVerbose(@"Browser: delete button pressed");
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	self.mode = BrowserModeBrowse;
	NSMutableArray *paths = [NSMutableArray array];
	for(NSIndexPath *indexPath in indexPaths) {
		[paths addObject:_paths[indexPath.row]];
	}
	NSMutableIndexSet *deletedIndices = [NSMutableIndexSet indexSet];
	[self deletePathAtIndex:0 inPaths:paths deletedIndices:deletedIndices];
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
	[self movePathAtIndex:0 inPaths:s_movePaths];
	s_movePaths = nil;
}

- (void)copyHereButtonPressed {
	DDLogVerbose(@"Browser: copy here button pressed");
	if(!s_movePaths || s_movePaths.count < 1) {
		return;
	}
	[self copyPathAtIndex:0 inPaths:s_movePaths];
	s_movePaths = nil;
}

#pragma mark Private

- (void)showEditBrowserForMode:(BrowserMode)mode {
	NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
	if(indexPaths.count < 1) {
		return;
	}
	s_movePaths = [NSMutableArray array];
	for(NSIndexPath *indexPath in indexPaths) { // save selected paths
		[s_movePaths addObject:_paths[indexPath.row]];
	}
	Browser *browserLayer = [self.root newBrowser]; // use subclass
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browserLayer];
	browserLayer.title = [NSString stringWithFormat:@"%@ %lu item%@",
						  (mode == BrowserModeMove ? @"Moving" : @"Copying"),
						  (unsigned long)s_movePaths.count, (s_movePaths.count > 1 ? @"s" : @"")];
	browserLayer.directoriesOnly = YES;
	browserLayer.mode = mode;
	navigationController.toolbarHidden = NO;
	navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
	navigationController.modalPresentationStyle = (Util.isDeviceATablet ? UIModalPresentationFormSheet : UIModalPresentationPageSheet);
	navigationController.modalInPopover = YES;
	[browserLayer loadDirectory:_directory relativeTo:Util.documentsPath]; // load after nav controller is set
	[self.navigationController presentViewController:navigationController animated:YES completion:nil];
	self.mode = BrowserModeBrowse; // reset now so it's ready when move is done
}

// recursively move paths
- (void)movePathAtIndex:(NSUInteger)index inPaths:(NSArray *)paths {
	if(index >= paths.count) {
		// done
		[self.navigationController dismissViewControllerAnimated:YES completion:^{
			[s_moveRoot reloadDirectory];
			s_moveRoot = nil;
		}];
		return;
	}
	NSString *path = paths[index];
	index++;
	[self.root movePath:path toDirectory:self.directory completion:^(BOOL failed) {
		[self movePathAtIndex:index inPaths:paths]; // next
	}];
}

// recursively copy paths
- (void)copyPathAtIndex:(NSUInteger)index inPaths:(NSArray *)paths {
	if(index >= paths.count) {
		// done
		[self.navigationController dismissViewControllerAnimated:YES completion:^{
			[s_moveRoot reloadDirectory];
			s_moveRoot = nil;
		}];
		return;
	}
	NSString *path = paths[index];
	index++;
	[self.root copyPath:path toDirectory:self.directory completion:^(BOOL failed) {
		[self copyPathAtIndex:index inPaths:paths]; // next
	}];
}

// recursively rename paths
- (void)renamePathAtIndex:(NSUInteger)index inPaths:(NSArray *)paths {
	if(index >= paths.count) {
		// done
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
		[self reloadDirectory];
		return;
	}
	NSString *path = paths[index];
	index++;
	[self.root showRenameDialogForPath:path completion:^{
		[self renamePathAtIndex:index inPaths:paths]; // next
	}];
}

// recursively delete paths
- (void)deletePathAtIndex:(NSUInteger)index inPaths:(NSArray *)paths
			 deletedIndices:(NSMutableIndexSet *)deletedIndices {
	if(index >= paths.count) {
		// delete from model & view
		NSMutableArray *deletedIndexPaths = [NSMutableArray array];
		[deletedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[deletedIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
		}];
		[self.tableView beginUpdates];
		[_paths removeObjectsAtIndexes:deletedIndices]; // do this in one go
		[self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		[self.tableView endUpdates];

		// done
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
		return;
	}
	NSUInteger currentIndex = index;
	NSString *path = paths[currentIndex];
	index++;
	__block NSMutableIndexSet *currentDeletedIndices = deletedIndices;
	[self.root deletePath:path completion:^(BOOL failed) {
		// next
		if(!failed) {
			[currentDeletedIndices addIndex:currentIndex];
		}
		[self deletePathAtIndex:index inPaths:paths deletedIndices:currentDeletedIndices];
	}];
}

@end
