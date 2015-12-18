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

#import "Log.h"
#import "Util.h"

// make life easier here ...
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"

static FileBrowser *s_moveRoot; //< browser layer that invoked a move edit
static NSMutableArray *s_movePaths; //< paths to move

@interface FileBrowser () {
	
	// for maintaining the scroll pos when navigating back,
	// from http://make-smart-iphone-apps.blogspot.com/2011/04/how-to-maintain-uitableview-scrolled.html
	CGPoint savedScrollPos;
}

// readwrite overrides
@property (strong, readwrite, nonatomic) NSString *currentDir;
@property (strong, readwrite, nonatomic) NSMutableArray *paths;
@property (readwrite, nonatomic) FileBrowserMode mode;
@property (readwrite, nonatomic) FileBrowser *root;
@property (readwrite, nonatomic) FileBrowser *top;

// set nav bar & tool bar buttons
//- (void)updateNavigationUI;

// create/overwrite a file, does not check existence
- (BOOL)_createFile:(NSString *)file;

@end

@implementation FileBrowser

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
	savedScrollPos = CGPointZero;
	self.paths = [[NSMutableArray alloc] init];
	_mode = FileBrowserModeBrowse;
	self.directoriesOnly = NO;
	self.showEditButton = YES;
	self.showMoveButton = YES;
	self.canSelectDirectories = NO;
	self.canAddFiles = YES;
	self.canAddDirectories = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// make sure the cell class is known
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"FileBrowserCell"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// make sure tool bar is visible
	self.navigationController.toolbarHidden = NO;

	// reset to saved pos
	//[self.tableView setContentOffset:savedScrollPos animated:NO];
}

#pragma mark Present

- (void)presentAnimated:(BOOL)animated {
	UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	[self presentFromViewController:root animated:animated];
}

- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated {
	if(!self.navigationController) {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
	}
	[controller presentViewController:self.navigationController animated:YES completion:nil];
}

#pragma mark Location

// file access error codes:
// https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html

- (void)loadDirectory:(NSString *)dirPath {
	NSError *error;
	DDLogVerbose(@"FileBrowser: loading directory %@", dirPath);
	
	// clear any existing layers
	[self.navigationController popToRootViewControllerAnimated:NO];
	
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
	self.currentDir = dirPath;
	[self.tableView reloadData];
}

- (void)loadDirectory:(NSString *)dirPath relativeTo:(NSString *)basePath {
	DDLogVerbose(@"FileBrowser: loading directory %@ relative to %@", dirPath, basePath);
	NSMutableArray *dirComponents = [NSMutableArray arrayWithArray:[dirPath componentsSeparatedByString:@"/"]];
	NSMutableArray *baseComponents = [NSMutableArray arrayWithArray:[basePath componentsSeparatedByString:@"/"]];
	if(baseComponents.count == 0 || dirComponents.count == 0) {
		DDLogWarn(@"FileBrowser: cannot loadDirectory, basePath and/or dirPath are empty");
		return;
	}
	if(baseComponents.count > dirComponents.count) {
		DDLogWarn(@"FileBrowser: cannot loadDirectory, basePath is longer than dirPath");
		return;
	}
	for(int i = 0; i < baseComponents.count; ++i) {
		if(![dirComponents[i] isEqualToString:baseComponents[i]]) {
			DDLogWarn(@"FileBrowser: cannot loadDirectory, dirPath is not a child of basePath");
			return;
		}
	}
	unsigned int count = baseComponents.count-1;
	NSMutableArray *components = [NSMutableArray arrayWithArray:baseComponents];
	for(int i = count; i < dirComponents.count; ++i) {
		if(i > count) {
			[components addObject:dirComponents[i]];
		}
		BOOL isDir = NO;
		NSString *path = [components componentsJoinedByString:@"/"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
			DDLogWarn(@"FileBrowser: stopped loading, %@ doesn't exist", [path lastPathComponent]);
			return;
		}
		if(!isDir) {
			DDLogWarn(@"FileBrowser: stopped loading, %@ is a file", [path lastPathComponent]);
			return;
		}
		DDLogVerbose(@"FileBrowser: now pushing folder %@", [path lastPathComponent]);
		if(i == count) { // load first layer, don't push
			path = [components componentsJoinedByString:@"/"];
			[self loadDirectory:path];
		}
		else { // push browser layer
			if(!self.navigationController) { // make sure there is a nav controller for the layers
				UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
			}
			FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
			browserLayer.root = self.root;
			browserLayer.mode = self.mode;
			//browserLayer.delegate = self.delegate;
			browserLayer.title = self.title;
			[browserLayer loadDirectory:path];
			[self.navigationController pushViewController:browserLayer animated:NO];
		}
	}
}

- (void)reloadDirectory {
	[self.paths removeAllObjects];
	[self loadDirectory:self.currentDir];
	[self.tableView reloadData];
}

- (void)unloadDirectory {
	[self.paths removeAllObjects];
	[self.tableView reloadData];
	//[self.tableView setNeedsDisplay];
}

- (void)clearDirectory {
	[self unloadDirectory];
	self.currentDir = nil;
}

#pragma mark Dialogs

- (void)showNewFileDialog {
	DDLogVerbose(@"FileBrowser: new file dialog");
	if(!self.currentDir) {
		DDLogWarn(@"FileBrowser: couldn't show new file dialog, currentDir not set (loadDirectory first?)");
		return;
	}
	NSString *title = @"Create new file", *message;
	if(self.root.extensions) {
		if(self.root.extensions.count == 1) {
			title = [NSString stringWithFormat:@"Create new .%@ file", [self.root.extensions objectAtIndex:0]];
			message = nil;
		}
		else {
			message = [NSString stringWithFormat:@"(include required extension: .%@)", [self.root.extensions componentsJoinedByString:@", ."]];
		}
	}
	else {
		message = @"(include extension aka \"file.txt\")";
	}
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"Create new file"
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Create
			NSString *file = [alertView textFieldAtIndex:0].text;
			if(self.root.extensions) {
				if(self.root.extensions.count == 1) {
					file = [[alertView textFieldAtIndex:0].text stringByAppendingPathExtension:[self.root.extensions objectAtIndex:0]];
				}
				else {
					if(![self.root.extensions containsObject:[file pathExtension]]) {
						DDLogWarn(@"FileBrowser: couldn't create \"%@\", missing one of the required extensions: %@", [file lastPathComponent], [self.root.extensions componentsJoinedByString:@", "]);
						NSString *title = [NSString stringWithFormat:@"Couldn't create \"%@\"", [file lastPathComponent]];
						NSString *message = [NSString stringWithFormat:@"Missing one of the required file extensions: .%@", [self.root.extensions componentsJoinedByString:@", ."]];
						UIAlertView *alertView = [[UIAlertView alloc]
												  initWithTitle:title
												  message:message
												  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
						[alertView show];
						return;
					}
				}
			}
			DDLogVerbose(@"FileBrowser: new file: %@", file);
			if([self createFile:file]) {
				[self reloadDirectory];
				if([self.root.delegate respondsToSelector:@selector(fileBrowser:createdFile:)]) {
					[self.root.delegate fileBrowser:self.root createdFile:file];
				}
			}
		}
	};
	[alertView show];
}

- (void)showNewDirectoryDialog {
	DDLogVerbose(@"FileBrowser: new directory dialog");
	if(!self.currentDir) {
		DDLogWarn(@"FileBrowser: couldn't show new dir dialog, currentDir not set (loadDirectory first?)");
		return;
	}
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:@"Create new folder"
						  message:nil
						  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Create
			NSString *dir = [alertView textFieldAtIndex:0].text;
			DDLogVerbose(@"FileBrowser: new dir: %@", dir);
			if([self createDirectory:dir]) {
				[self reloadDirectory];
				if([self.root.delegate respondsToSelector:@selector(fileBrowser:createdDirectory:)]) {
					[self.root.delegate fileBrowser:self.root createdDirectory:dir];
				}
			}
		}
	};
	[alert show];
}

- (void)showRenameDialogForPath:(NSString *)path {
	DDLogVerbose(@"FileBrowser: rename dialog");
	if(!self.currentDir) {
		DDLogWarn(@"FileBrowser: couldn't show rename dialog, currentDir not set (loadDirectory first?)");
		return;
	}
	BOOL isDir = [Util isDirectory:path];
	NSString *title = [NSString stringWithFormat:@"Rename %@", [path lastPathComponent]];
	NSString *message = nil;
	if(!isDir) {
		if(self.root.extensions) {
			if(self.root.extensions.count > 1) {
				message = [NSString stringWithFormat:@"(include required extension: .%@)", [self.root.extensions componentsJoinedByString:@", ."]];
			}
		}
		else {
			message = @"(include extension aka \"file.txt\")";
		}
	}
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Done
			NSString *newPath = [self.currentDir stringByAppendingPathComponent:[alertView textFieldAtIndex:0].text];
			if(!isDir) {
				if(self.root.extensions.count == 1) {
					newPath = [newPath stringByAppendingPathExtension:[self.root.extensions objectAtIndex:0]];
				}
				else {
					if(![self.root.extensions containsObject:[newPath pathExtension]]) {
						DDLogWarn(@"FileBrowser: couldn't rename to \"%@\", missing one of the required extensions: %@", [newPath lastPathComponent], [self.root.extensions componentsJoinedByString:@", "]);
						NSString *title = [NSString stringWithFormat:@"Couldn't rename to \"%@\"", [newPath lastPathComponent]];
						NSString *message = [NSString stringWithFormat:@"Missing one of the required file extensions: .%@", [self.root.extensions componentsJoinedByString:@", ."]];
						UIAlertView *alertView = [[UIAlertView alloc]
											  initWithTitle:title
											  message:message
											  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
						[alertView show];
						return;
					}
				}
			}
			DDLogVerbose(@"FileBrowser: rename %@ to %@", [path lastPathComponent], [newPath lastPathComponent]);
			if([self renamePath:path to:newPath]) {
				[self reloadDirectory];
			}
		}
	};
	[alertView show];
}

#pragma mark Utils

- (BOOL)createFile:(NSString *)file {
	NSError *error;
	DDLogVerbose(@"FileBrowser: creating file: %@", file);
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:file];
	if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?", file, [self.currentDir lastPathComponent]];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Overwrite?"
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
		alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
			if(buttonIndex == 1) { // Ok
				[self _createFile:file];
			}
		};
		[alert show];
		return NO;
	}
	return [self _createFile:file];
}

- (BOOL)createDirectory:(NSString *)dir {
	NSError *error;
	DDLogVerbose(@"FileBrowser: creating dir: %@", dir);
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:dir];
	if(![[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:NO attributes:NULL error:&error]) {
			DDLogError(@"FileBrowser: couldn't create directory %@, error: %@", destPath, error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:[NSString stringWithFormat:@"Couldn't create folder \"%@\"", dir]
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
	}
	else {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Please choose a different name.", dir, [self.currentDir lastPathComponent]];
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Folder already exists"
								  message:message
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
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:title
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

- (BOOL)movePath:(NSString *)path toDirectory:(NSString *)newDir {
	NSError *error;
	NSString *newPath = [newDir stringByAppendingPathComponent:[path lastPathComponent]];
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if(![[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"FileBrowser: couldn't move %@ to %@, error: %@", path, newPath, error.localizedDescription);
			NSString *title = [NSString stringWithFormat:@"Couldn't move %@ to \"%@\"", [path lastPathComponent], newDir];
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:title
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"FileBrowser: moved %@ to %@", path, newDir);
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
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:[NSString stringWithFormat:@"Couldn't delete %@", [path lastPathComponent]]
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

- (unsigned int)fileCountForExtension:(NSString *)extension {
	unsigned int i = 0;
	for(NSString *p in self.paths) {
		if([[p pathExtension] isEqualToString:extension]) {
			i++;
		}
	}
	return i;
}

- (unsigned int)fileCountForExtensions {
	unsigned int i = 0;
	for(NSString *ext in self.root.extensions) {
		i += [self fileCountForExtension:ext];
	}
	return i;
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
			if(self.canAddFiles || self.canAddDirectories) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
									   target:self
									   action:@selector(addButtonPressed)]];
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
									   target:nil
									   action:nil]];
			}
			if(self.directoriesOnly && self.canSelectDirectories) {
				[barButtons addObject:[[UIBarButtonItem alloc]
									   initWithTitle:@"Choose Folder"
									   style:UIBarButtonItemStylePlain
									   target:self
									   action:@selector(chooseFolderButtonPressed)]];
			}
			if(self.showEditButton) {
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
			if(self.showMoveButton) {
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
- (void)setCurrentDir:(NSString *)currentDir {
	_currentDir = currentDir;
	if(self.currentDir) {
		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:[self.currentDir lastPathComponent]
												 style:UIBarButtonItemStylePlain
												 target:self
												 action:@selector(backButtonPressed:)];
	}
	else {
		self.navigationItem.backBarButtonItem = nil;
	}
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

// nav bar title is generated based on this value
- (NSString *)title {
	return (super.title ? super.title : [self.currentDir lastPathComponent]);
}

- (FileBrowser *)top {
	if(self.navigationController) {
		if([self.navigationController.topViewController isKindOfClass:[FileBrowser class]]) {
			return (FileBrowser *)self.navigationController.topViewController;
		}
		DDLogWarn(@"FileBrowser: nav controller stack top is not a FileBrowser");
	}
	return self;
}

- (FileBrowser *)root {
	if(!_root) {
		return self;
	}
	return _root;
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
	NSString *path = self.paths[indexPath.row];
	BOOL isDir;
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
				FileBrowser *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
				browserLayer.root = self.root;
				browserLayer.mode = self.mode;
				//browserLayer.delegate = self.delegate;
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
			savedScrollPos = [tableView contentOffset];
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
			[self deletePath:self.paths[indexPath.row]];
			[self.paths removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

// empty footer to hide empty cells & separators
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//	UIView *view = [[UIView alloc] init];
//	return view;
//}

#pragma mark Browsing UI

- (void)addButtonPressed {
	DDLogVerbose(@"FileBrowser: add button pressed");
	UIActionSheet *sheet = [[UIActionSheet alloc]
							initWithTitle:nil delegate:nil
							cancelButtonTitle:@"Cancel"
							destructiveButtonTitle:nil
							otherButtonTitles:nil];
	if(self.canAddFiles) {
		[sheet addButtonWithTitle:@"New File"];
	}
	if(self.canAddDirectories) {
		[sheet addButtonWithTitle:@"New Folder"];
	}
	sheet.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
		NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
		if([button isEqualToString:@"New File"]) {
			if(self.canAddFiles) {
				[self showNewFileDialog];
			}
		}
		else if([button isEqualToString:@"New Folder"]) {
			if(self.canAddDirectories) {
				[self showNewDirectoryDialog];
			}
		}
	};
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (void)chooseFolderButtonPressed {
	DDLogVerbose(@"FileBrowser: choose folder button pressed");
	if([self.root.delegate respondsToSelector:@selector(fileBrowser:selectedDirectory:)]) {
		[self.root.delegate fileBrowser:self.root selectedDirectory:self.currentDir];
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
	[browserLayer loadDirectory:self.currentDir relativeTo:[Util documentsPath]]; // load after nav controller is set
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
		[self showRenameDialogForPath:path];
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
		if([self deletePath:[self.paths objectAtIndex:indexPath.row]]) {
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
	[self showNewDirectoryDialog];
}

- (void)moveHereButtonPressed {
	DDLogVerbose(@"FileBrowser: move here button pressed");
	if(!s_movePaths || s_movePaths.count < 1) {
		return;
	}
	for(NSString *path in s_movePaths) {
		[self movePath:path toDirectory:self.currentDir];
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[s_moveRoot reloadDirectory]; // show changes after move
	s_moveRoot = nil;
	s_movePaths = nil;
}

#pragma mark Private

- (BOOL)_createFile:(NSString *)file {
	NSError *error;
	NSString* destPath = [self.currentDir stringByAppendingPathComponent:file];
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
