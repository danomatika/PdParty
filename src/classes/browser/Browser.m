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
#import "Browser.h"

#import "Log.h"
#import "Util.h"

// make life easier here ...
#import "UIAlertView+Blocks.h"

@interface Browser () {}

// top browser layer in the nav controller or self if none
@property (readonly, nonatomic) BrowserLayer *top;

// create/overwrite a file path, does not check existence
- (BOOL)_createFilePath:(NSString *)path;

// move/overwrite a file path in to a new dir, does not check existence
- (BOOL)_movePath:(NSString *)path toDirectory:(NSString *)newDir;

@end

@implementation Browser

- (void)setup {
	[super setup];
	self.dataDelegate = self;
	self.directoriesOnly = NO;
	self.showEditButton = YES;
	self.showMoveButton = YES;
	self.canSelectDirectories = NO;
	self.canAddFiles = YES;
	self.canAddDirectories = YES;
}

#pragma mark Present

- (void)presentAnimated:(BOOL)animated {
	UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
	[self presentFromViewController:root animated:animated];
}

- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated {
	UINavigationController *navigationController = self.navigationController;
	if(!navigationController) {
		navigationController = [[UINavigationController alloc] initWithRootViewController:self];
		navigationController.modalPresentationStyle = self.modalPresentationStyle;
	}
	[controller presentViewController:navigationController animated:animated completion:nil];
}

#pragma mark Location

// clear any existing layers
- (BOOL)loadDirectory:(NSString *)dirPath {
	[self.navigationController popToViewController:self animated:NO];
	return [super loadDirectory:dirPath];
}

- (BOOL)loadDirectory:(NSString *)dirPath relativeTo:(NSString *)basePath {
	DDLogVerbose(@"Browser: loading directory %@ relative to %@", dirPath, basePath);
	NSMutableArray *dirComponents = [NSMutableArray arrayWithArray:[dirPath componentsSeparatedByString:@"/"]];
	NSMutableArray *baseComponents = [NSMutableArray arrayWithArray:[basePath componentsSeparatedByString:@"/"]];
	if(baseComponents.count == 0 || dirComponents.count == 0) {
		DDLogWarn(@"Browser: cannot loadDirectory, basePath and/or dirPath are empty");
		return NO;
	}
	if(baseComponents.count > dirComponents.count) {
		DDLogWarn(@"Browser: cannot loadDirectory, basePath is longer than dirPath");
		return NO;
	}
	for(int i = 0; i < baseComponents.count; ++i) {
		if(![dirComponents[i] isEqualToString:baseComponents[i]]) {
			DDLogWarn(@"Browser: cannot loadDirectory, dirPath is not a child of basePath");
			return NO;
		}
	}
	unsigned int count = (unsigned int)baseComponents.count-1;
	NSMutableArray *components = [NSMutableArray arrayWithArray:baseComponents];
	for(int i = count; i < dirComponents.count; ++i) {
		if(i > count) {
			[components addObject:dirComponents[i]];
		}
		BOOL isDir = NO;
		NSString *path = [components componentsJoinedByString:@"/"];
		if(![NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
			DDLogWarn(@"Browser: stopped loading, %@ doesn't exist", path.lastPathComponent);
			return NO;
		}
		if(!isDir) {
			DDLogWarn(@"Browser: stopped loading, %@ is a file", path.lastPathComponent);
			return NO;
		}
		DDLogVerbose(@"Browser: now pushing folder %@", path.lastPathComponent);
		if(i == count) { // load first layer, don't push
			path = [components componentsJoinedByString:@"/"];
			[self loadDirectory:path];
		}
		else { // push browser layer
			UINavigationController *navigationController = self.navigationController;
			if(!navigationController) { // make sure there is a nav controller for the layers
				navigationController = [[UINavigationController alloc] initWithRootViewController:self];
			}
			BrowserLayer *browserLayer = [[Browser alloc] initWithStyle:UITableViewStylePlain];
			browserLayer.root = self.root;
			browserLayer.mode = self.mode;
			browserLayer.title = self.title;
			[browserLayer loadDirectory:path];
			[navigationController pushViewController:browserLayer animated:NO];
		}
	}
	return YES;
}

// clear any existing layers
- (void)clearDirectory {
	[self.navigationController popToViewController:self animated:NO];
	[super clearDirectory];
}

#pragma mark Dialogs

// using UIAlertView didDimissBlock instead of tapBlock as dialogs would
// *sometimes* disappear and leave app in non-interactive state:
// http://stackoverflow.com/questions/6611380/uialertview-and-uiactionview-disappear-app-left-in-inconsistent-state

- (void)showNewFileDialog {
	DDLogVerbose(@"Browser: new file dialog");
	if(!self.top.directory) {
		DDLogWarn(@"Browser: couldn't show new file dialog, directory not set (loadDirectory first?)");
		return;
	}
	NSString *title = @"Create new file", *message;
	if(self.root.extensions) {
		if(self.root.extensions.count == 1) {
			title = [NSString stringWithFormat:@"Create new .%@ file", self.root.extensions.firstObject];
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
							  initWithTitle:title
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	alertView.didDismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Create
			NSString *file = [alertView textFieldAtIndex:0].text;
			if([file isEqualToString:@""]) {
				return;
			}
			if(self.root.extensions) {
				if(self.root.extensions.count == 1) {
					file = [[alertView textFieldAtIndex:0].text stringByAppendingPathExtension:self.root.extensions.firstObject];
				}
				else {
					if(![self.root.extensions containsObject:file.pathExtension]) {
						DDLogWarn(@"Browser: couldn't create \"%@\", missing one of the required extensions: %@", file.lastPathComponent, [self.root.extensions componentsJoinedByString:@", "]);
						NSString *title = [NSString stringWithFormat:@"Couldn't create \"%@\"", file.lastPathComponent];
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
			DDLogVerbose(@"Browser: new file: %@", file);
			file = [self.top.directory stringByAppendingPathComponent:file];
			if([self createFilePath:file]) {
				[self.top reloadDirectory];
				if([self.root.delegate respondsToSelector:@selector(browser:createdFile:)]) {
					[self.root.delegate browser:self.root createdFile:file];
				}
			}
		}
	};
	[alertView show];
}

- (void)showNewDirectoryDialog {
	DDLogVerbose(@"Browser: new directory dialog");
	if(!self.top.directory) {
		DDLogWarn(@"Browser: couldn't show new dir dialog, directory not set (loadDirectory first?)");
		return;
	}
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:@"Create new folder"
						  message:nil
						  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	alert.didDismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Create
			NSString *dir = [alertView textFieldAtIndex:0].text;
			if([dir isEqualToString:@""]) {
				return;
			}
			DDLogVerbose(@"Browser: new dir: %@", dir);
			dir = [self.top.directory stringByAppendingPathComponent:dir];
			if([self createDirectoryPath:dir]) {
				[self.top reloadDirectory];
				if([self.root.delegate respondsToSelector:@selector(browser:createdDirectory:)]) {
					[self.root.delegate browser:self.root createdDirectory:dir];
				}
			}
		}
	};
	[alert show];
}

- (void)showRenameDialogForPath:(NSString *)path {
	DDLogVerbose(@"Browser: rename dialog");
	if(!self.top.directory) {
		DDLogWarn(@"Browser: couldn't show rename dialog, directory not set (loadDirectory first?)");
		return;
	}
	BOOL isDir = [Util isDirectory:path];
	NSString *title = [NSString stringWithFormat:@"Rename %@", path.lastPathComponent];
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
	alertView.didDismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
		if(buttonIndex == 1) { // Done
			NSString *newPath = [self.top.directory stringByAppendingPathComponent:[alertView textFieldAtIndex:0].text];
			if(!isDir) {
				if(self.root.extensions.count == 1) {
					newPath = [newPath stringByAppendingPathExtension:self.root.extensions.firstObject];
				}
				else {
					if(![self.root.extensions containsObject:newPath.pathExtension]) {
						DDLogWarn(@"Browser: couldn't rename to \"%@\", missing one of the required extensions: %@", newPath.lastPathComponent, [self.root.extensions componentsJoinedByString:@", "]);
						NSString *title = [NSString stringWithFormat:@"Couldn't rename to \"%@\"", newPath.lastPathComponent];
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
			DDLogVerbose(@"Browser: rename %@ to %@", path.lastPathComponent, newPath.lastPathComponent);
			if([self renamePath:path to:newPath]) {
				[self.top reloadDirectory];
			}
		}
	};
	[alertView show];
}

#pragma mark Utils

- (BOOL)createFilePath:(NSString *)path {
	NSError *error;
	DDLogVerbose(@"Browser: creating file: %@", path.lastPathComponent);
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?",
							 path.lastPathComponent,
							 path.stringByDeletingLastPathComponent.lastPathComponent];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Overwrite?"
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
		alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
			if(buttonIndex == 1) { // Ok
				[NSFileManager.defaultManager removeItemAtPath:path error:nil];
				if([self _createFilePath:path]) {
					[self.top reloadDirectory];
					if([self.root.delegate respondsToSelector:@selector(browser:createdFile:)]) {
						[self.root.delegate browser:self.root createdFile:path];
					}
				}
			}
		};
		[alert show];
		return NO;
	}
	return [self _createFilePath:path];
}

- (BOOL)createDirectoryPath:(NSString *)path {
	NSError *error;
	DDLogVerbose(@"Browser: creating dir: %@", path.lastPathComponent);
	if(![NSFileManager.defaultManager fileExistsAtPath:path]) {
		if(![NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:NULL error:&error]) {
			DDLogError(@"Browser: couldn't create directory %@, error: %@", path.lastPathComponent, error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:[NSString stringWithFormat:@"Couldn't create folder \"%@\"", path.lastPathComponent]
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
	}
	else {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Please choose a different name.",
							 path.lastPathComponent,
							 path.stringByDeletingLastPathComponent.lastPathComponent];
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
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		if(![NSFileManager.defaultManager moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"Browser: couldn't rename %@ to %@, error: %@", path, newPath, error.localizedDescription);
			NSString *title = [NSString stringWithFormat:@"Couldn't rename %@ to \"%@\"", path.lastPathComponent, newPath.lastPathComponent];
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:title
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"Browser: renamed %@ to %@", path, newPath);
		}
	}
	else {
		DDLogWarn(@"Browser: couldn't rename %@, path not found", path);
	}
	return YES;
}

- (BOOL)movePath:(NSString *)path toDirectory:(NSString *)newDir {
	NSError *error;
	NSString *newPath = [newDir stringByAppendingPathComponent:path.lastPathComponent];
	if(![NSFileManager.defaultManager fileExistsAtPath:path]) {
		DDLogWarn(@"Browser: couldn't move %@, path not found", path);
		return NO;
	}
	if([NSFileManager.defaultManager fileExistsAtPath:newPath]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?",
							 path.lastPathComponent,
							 path.stringByDeletingLastPathComponent.lastPathComponent];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Overwrite?"
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
		alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
			if(buttonIndex == 1) { // Ok
				if([self _movePath:path toDirectory:newDir]) {
					[self.top reloadDirectory];
				}
			}
		};
		[alert show];
		return NO;
	}
	return [self _movePath:path toDirectory:newDir];
}

- (BOOL)deletePath:(NSString *)path {
	NSError *error;
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
			DDLogError(@"Browser: couldn't delete %@, error: %@", path, error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:[NSString stringWithFormat:@"Couldn't delete %@", path.lastPathComponent]
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
		else {
			DDLogVerbose(@"Browser: deleted %@", path);
		}
	}
	else {
		DDLogWarn(@"Browser: couldn't delete %@, path not found", path);
	}
	return YES;
}

- (unsigned int)fileCountForExtension:(NSString *)extension {
	unsigned int i = 0;
	for(NSString *p in self.top.paths) {
		if([p.pathExtension isEqualToString:extension]) {
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

- (BOOL)pathHasAllowedExtension:(NSString *)path {
	return self.extensions ? [self.extensions containsObject:path.pathExtension] : NO;
}

#pragma mark Subclassing

- (UIBarButtonItem *)browsingModeRightBarItemForLayer:(BrowserLayer *)layer {
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:layer action:@selector(cancelButtonPressed)];
}

- (Browser *)newBrowser {
	return [[Browser alloc] initWithStyle:self.tableView.style];
}

#pragma mark BrowserDataDelegate

- (BOOL)browser:(Browser *)browser shouldAddPath:(NSString *)path isDir:(BOOL)isDir {
	return YES;
}

- (BOOL)browser:(Browser *)browser isPathSelectable:(NSString *)path isDir:(BOOL)isDir {
	return YES;
}

- (void)browser:(Browser *)browser styleCell:(UITableViewCell *)cell
		                             forPath:(NSString *)path
		                               isDir:(BOOL)isDir
                                isSelectable:(BOOL)isSelectable {
	if(isSelectable) {
		cell.textLabel.textColor = UIColor.blackColor;
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	}
	else {
		cell.textLabel.textColor = UIColor.grayColor;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	if(isDir) {
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		cell.textLabel.text = path.lastPathComponent;
	}
	else { // files
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		cell.textLabel.text = path.lastPathComponent;
	}
}

#pragma mark Overridden Getters/Setters

- (NSString *)directory {
	if(self.top == self) {
		return super.directory;
	}
	return self.top.directory;
}

- (NSMutableArray *)paths {
	if(self.top == self) {
		return super.paths;
	}
	return self.top.paths;
}

- (BOOL)isRootLayer {
	return self.top == self;
}

- (Browser *)top {
	if(self.navigationController) {
		return (Browser *)self.navigationController.topViewController;
	}
	return self;
}

- (Browser *)root {
	if(!super.root) {
		return self;
	}
	return super.root;
}

#pragma mark Private

- (BOOL)_createFilePath:(NSString *)path {
	NSError *error;
	if(![NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:NULL]) {
		DDLogError(@"Browser: couldn't create file %@", path);
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:[NSString stringWithFormat:@"Couldn't create file \"%@\"", path.lastPathComponent]
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	return YES;
}

- (BOOL)_movePath:(NSString *)path toDirectory:(NSString *)newDir {
	NSError *error;
	NSString *newPath = [newDir stringByAppendingPathComponent:path.lastPathComponent];
	if(![NSFileManager.defaultManager moveItemAtPath:path toPath:newPath error:&error]) {
		DDLogError(@"Browser: couldn't move %@ to %@, error: %@", path, newPath, error.localizedDescription);
		NSString *title = [NSString stringWithFormat:@"Couldn't move %@ to \"%@\"", path.lastPathComponent, newDir];
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:title
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	return YES;
}

@end
