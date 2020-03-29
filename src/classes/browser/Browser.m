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

@interface Browser () {}

// top browser layer in the nav controller or self if none
@property (readonly, nonatomic) BrowserLayer *top;

// create/overwrite a file path, does not check existence
- (BOOL)_createFilePath:(NSString *)path;

// move/overwrite a file path in to a new dir, does not check existence
- (BOOL)_movePath:(NSString *)path toDirectory:(NSString *)newDir completion:(void (^)(BOOL failed))completion;

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

- (void)showNewFileDialog {
	DDLogVerbose(@"Browser: new file dialog");
	if(!self.top.directory) {
		DDLogWarn(@"Browser: couldn't show new file dialog, directory not set (loadDirectory first?)");
		return;
	}
	NSString *title = @"Create New File", *message;
	if(self.root.extensions) {
		if(self.root.extensions.count == 1) {
			title = [NSString stringWithFormat:@"Create new .%@ file", self.root.extensions.firstObject];
			message = nil;
		}
		else {
			message = [NSString stringWithFormat:@"(include required extension: .%@)",
					   [self.root.extensions componentsJoinedByString:@", ."]];
		}
	}
	else {
		message = @"(include extension aka \"file.txt\")";
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																   message:message
														 cancelButtonTitle:@"Cancel"];
	[alert addTextFieldWithConfigurationHandler:nil];
	UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"Create"
														   style:UIAlertActionStyleDefault
														 handler:^(UIAlertAction * _Nonnull action) {
		NSString *file = alert.textFields.firstObject.text;
		if([file isEqualToString:@""]) {
			return;
		}
		if(self.root.extensions) {
			if(self.root.extensions.count == 1) {
				file = [file stringByAppendingPathExtension:self.root.extensions.firstObject];
			}
			else {
				if(![self.root.extensions containsObject:file.pathExtension]) {
					DDLogWarn(@"Browser: couldn't create \"%@\", missing one of the required extensions: %@",
							  file.lastPathComponent, [self.root.extensions componentsJoinedByString:@", "]);
					NSString *title = [NSString stringWithFormat:@"Couldn't create \"%@\"", file.lastPathComponent];
					NSString *message = [NSString stringWithFormat:@"Missing one of the required file extensions: .%@", [self.root.extensions componentsJoinedByString:@", ."]];
					[[UIAlertController alertControllerWithTitle:title
														 message:message
											   cancelButtonTitle:@"Ok"] show];
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
	}];
	[alert addAction:createAction];
	[alert show];
}

- (void)showNewDirectoryDialog {
	DDLogVerbose(@"Browser: new directory dialog");
	if(!self.top.directory) {
		DDLogWarn(@"Browser: couldn't show new dir dialog, directory not set (loadDirectory first?)");
		return;
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Create New Folder"
																   message:nil
														 cancelButtonTitle:@"Cancel"];
	[alert addTextFieldWithConfigurationHandler:nil];
	UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"Create"
														   style:UIAlertActionStyleDefault
														 handler:^(UIAlertAction * _Nonnull action) {
		NSString *dir = alert.textFields.firstObject.text;
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
	}];
	[alert addAction:createAction];
	[alert show];
}

- (void)showRenameDialogForPath:(NSString *)path completion:(void (^)(void))completion {
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
				message = [NSString stringWithFormat:@"(include required extension: .%@)",
						   [self.root.extensions componentsJoinedByString:@", ."]];
			}
		}
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																   message:message
														 cancelButtonTitle:nil];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * _Nonnull action) {
		if(completion) {
			completion();
		}
	}];
	UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done"
														 style:UIAlertActionStyleDefault
													   handler:^(UIAlertAction * _Nonnull action) {
		NSString *newPath = [self.top.directory stringByAppendingPathComponent:alert.textFields.firstObject.text];
		if(!isDir) {
			if(!self.root.extensions || self.root.extensions.count == 0) {
				// infer using provided or existing extension
				if([newPath.pathExtension isEqualToString:@""]) {
					newPath = [newPath stringByAppendingPathExtension:path.pathExtension];
				}
			}
			else if(self.root.extensions.count == 1) {
				// append default extension
				if(![newPath.pathExtension isEqualToString:self.root.extensions.firstObject]) {
					newPath = [newPath stringByAppendingPathExtension:self.root.extensions.firstObject];
				}
			}
			else if(![self.root.extensions containsObject:newPath.pathExtension]) {
				// check for required extension
				DDLogWarn(@"Browser: couldn't rename to \"%@\", missing one of the required extensions: %@",
						  newPath.lastPathComponent, [self.root.extensions componentsJoinedByString:@", "]);
				NSString *title = [NSString stringWithFormat:@"Couldn't rename to \"%@\"", newPath.lastPathComponent];
				NSString *message = [NSString stringWithFormat:@"Missing one of the required file extensions: .%@",
									 [self.root.extensions componentsJoinedByString:@", ."]];
				UIAlertController *ealert = [UIAlertController alertControllerWithTitle:title
																				 message:message
																	   cancelButtonTitle:nil];
				UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok"
																   style:UIAlertActionStyleCancel
																 handler:^(UIAlertAction * _Nonnull action) {
					if(completion) {
						completion();
					}
				}];
				[ealert addAction:okAction];
				[ealert show];
				return;
			}
		}
		DDLogVerbose(@"Browser: rename %@ to %@", path.lastPathComponent, newPath.lastPathComponent);
		if([self renamePath:path to:newPath completion:^(BOOL failed) {
			if(completion) {
				completion();
			}
		}]) {
			[self.top reloadDirectory];
		}
	}];
	[alert addAction:cancelAction];
	[alert addAction:doneAction];
	[alert addTextFieldWithConfigurationHandler:nil];
	[alert show];
}

#pragma mark Utils

- (BOOL)createFilePath:(NSString *)path {
	NSError *error;
	DDLogVerbose(@"Browser: creating file: %@", path.lastPathComponent);
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?",
							 path.lastPathComponent,
							 path.stringByDeletingLastPathComponent.lastPathComponent];
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Already Exists"
																	   message:message
															 cancelButtonTitle:@"Cancel"];
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Overwrite"
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction * _Nonnull action) {
			[NSFileManager.defaultManager removeItemAtPath:path error:nil];
			if([self _createFilePath:path]) {
				[self.top reloadDirectory];
				if([self.root.delegate respondsToSelector:@selector(browser:createdFile:)]) {
					[self.root.delegate browser:self.root createdFile:path];
				}
			}
		}];
		[alert addAction:okAction];
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
			[[UIAlertController alertControllerWithTitle:@"Create Failed"
												 message:error.localizedDescription
									   cancelButtonTitle:@"Ok"] show];
			return NO;
		}
	}
	else {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Please choose a different name.",
							 path.lastPathComponent,
							 path.stringByDeletingLastPathComponent.lastPathComponent];
		[[UIAlertController alertControllerWithTitle:@"Already Exists"
											 message:message
								   cancelButtonTitle:@"Ok"] show];
		return NO;
	}
	return YES;
}

- (BOOL)renamePath:(NSString *)path to:(NSString *)newPath completion:(void (^)(BOOL failed))completion {
	NSError *error;
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		if(![NSFileManager.defaultManager moveItemAtPath:path toPath:newPath error:&error]) {
			DDLogError(@"Browser: couldn't rename %@ to %@, error: %@", path, newPath, error.localizedDescription);
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename Failed"
																		   message:error.localizedDescription
																 cancelButtonTitle:nil];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok"
															   style:UIAlertActionStyleCancel
															 handler:^(UIAlertAction * _Nonnull action) {
				if(completion) {
					completion(YES);
				}
			}];
			[alert addAction:okAction];
			[alert show];
			return NO;
		}
		else {
			DDLogVerbose(@"Browser: renamed %@ to %@", path, newPath);
		}
	}
	else {
		DDLogWarn(@"Browser: couldn't rename %@, path not found", path);
	}
	if(completion) {
		completion(NO);
	}
	return YES;
}

- (BOOL)movePath:(NSString *)path toDirectory:(NSString *)newDir completion:(void (^)(BOOL failed))completion {
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
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Already Exists"
																	   message:message
															 cancelButtonTitle:nil];
		UIAlertAction *skipAction = [UIAlertAction actionWithTitle:@"Skip"
															   style:UIAlertActionStyleCancel
															 handler:^(UIAlertAction * _Nonnull action) {
			if(completion) {
				completion(NO);
			}
		}];
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Overwrite"
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction * _Nonnull action) {
			[NSFileManager.defaultManager removeItemAtPath:newPath error:nil];
			if([self _movePath:path toDirectory:newDir completion:^(BOOL failed) {
				if(!failed) {
					[self.top reloadDirectory];
				}
				if(completion) {
					completion(failed);
				}
			}]) {
			   return;
			}
			if(completion) {
				completion(NO);
			}
		}];
		[alert addAction:skipAction];
		[alert addAction:okAction];
		[alert show];
		return NO;
	}
	return [self _movePath:path toDirectory:newDir completion:completion];
}

- (BOOL)deletePath:(NSString *)path completion:(void (^)(BOOL failed))completion {
	NSError *error;
	if([NSFileManager.defaultManager fileExistsAtPath:path]) {
		if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
			DDLogError(@"Browser: couldn't delete %@, error: %@", path, error.localizedDescription);
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Failed"
																		   message:error.localizedDescription
																 cancelButtonTitle:nil];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok"
															   style:UIAlertActionStyleCancel
															 handler:^(UIAlertAction * _Nonnull action) {
				if(completion) {
					completion(YES);
				}
			}];
			[alert addAction:okAction];
			[alert show];
			return NO;
		}
		else {
			DDLogVerbose(@"Browser: deleted %@", path);
		}
	}
	else {
		DDLogWarn(@"Browser: couldn't delete %@, path not found", path);
	}
	if(completion) {
		completion(NO);
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
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
														 target:layer
														 action:@selector(cancelButtonPressed)];
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
		[[UIAlertController alertControllerWithTitle:@"Create Failed"
											 message:error.localizedDescription
								   cancelButtonTitle:@"Ok"] show];
		return NO;
	}
	return YES;
}

- (BOOL)_movePath:(NSString *)path toDirectory:(NSString *)newDir completion:(void (^)(BOOL failed))completion {
	NSError *error;
	NSString *newPath = [newDir stringByAppendingPathComponent:path.lastPathComponent];
	if(![NSFileManager.defaultManager moveItemAtPath:path toPath:newPath error:&error]) {
		DDLogError(@"Browser: couldn't move %@ to %@, error: %@", path, newPath, error.localizedDescription);
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Move Failed"
																	   message:error.localizedDescription
															 cancelButtonTitle:nil];
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok"
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * _Nonnull action) {
			if(completion) {
				completion(YES);
			}
		}];
		[alert addAction:okAction];
		[alert show];
		return NO;
	}
	if(completion) {
		completion(NO);
	}
	return YES;
}

@end
