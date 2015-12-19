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

@interface FileBrowser () {}

// top browser layer in the nav controller or self if none
@property (readonly, nonatomic) FileBrowserLayer *top;

// create/overwrite a file path, does not check existence
- (BOOL)_createFilePath:(NSString *)path;

@end

@implementation FileBrowser

- (void)setup {
	[super setup];
	self.directoriesOnly = NO;
	self.showEditButton = YES;
	self.showMoveButton = YES;
	self.canSelectDirectories = NO;
	self.canAddFiles = YES;
	self.canAddDirectories = YES;
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

// clear any existing layers
- (void)loadDirectory:(NSString *)dirPath {
	[self.navigationController popToViewController:self animated:NO];
	[super loadDirectory:dirPath];
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
			FileBrowserLayer *browserLayer = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
			browserLayer.root = self.root;
			browserLayer.mode = self.mode;
			browserLayer.title = self.title;
			[browserLayer loadDirectory:path];
			[self.navigationController pushViewController:browserLayer animated:NO];
		}
	}
}

// clear any existing layers
- (void)clearDirectory {
	[self.navigationController popToViewController:self animated:NO];
	[super clearDirectory];
}

#pragma mark Dialogs

- (void)showNewFileDialog {
	DDLogVerbose(@"FileBrowser: new file dialog");
	if(!self.top.directory) {
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
			if([self createFilePath:[self.top.directory stringByAppendingPathComponent:file]]) {
				[self.top reloadDirectory];
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
	if(!self.top.directory) {
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
			if([self createDirectoryPath:[self.top.directory stringByAppendingPathComponent:dir]]) {
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
	if(!self.top.directory) {
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
			NSString *newPath = [self.top.directory stringByAppendingPathComponent:[alertView textFieldAtIndex:0].text];
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

- (BOOL)createFilePath:(NSString *)path {
	NSError *error;
	DDLogVerbose(@"FileBrowser: creating file: %@", [path lastPathComponent]);
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Overwrite it?",
							 [path lastPathComponent],
							 [[path stringByDeletingLastPathComponent] lastPathComponent]];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Overwrite?"
							  message:message
							  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
		alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
			if(buttonIndex == 1) { // Ok
				[self _createFilePath:path];
			}
		};
		[alert show];
		return NO;
	}
	return [self _createFilePath:path];
}

- (BOOL)createDirectoryPath:(NSString *)path {
	NSError *error;
	DDLogVerbose(@"FileBrowser: creating dir: %@", [path lastPathComponent]);
	if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:NULL error:&error]) {
			DDLogError(@"FileBrowser: couldn't create directory %@, error: %@", [path lastPathComponent], error.localizedDescription);
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:[NSString stringWithFormat:@"Couldn't create folder \"%@\"", [path lastPathComponent]]
									  message:error.localizedDescription
									  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alertView show];
			return NO;
		}
	}
	else {
		NSString *message = [NSString stringWithFormat:@"\"%@\" already exists in %@. Please choose a different name.",
							 [path lastPathComponent],
							 [[path stringByDeletingLastPathComponent] lastPathComponent]];
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
	for(NSString *p in self.top.paths) {
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

- (BOOL)pathHasAllowedExtension:(NSString *)path {
	return self.extensions ? [self.extensions containsObject:[path pathExtension]] : NO;
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
	if(!super.root) {
		return self;
	}
	return super.root;
}

#pragma mark Private

- (BOOL)_createFilePath:(NSString *)path {
	NSError *error;
	if(![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:NULL]) {
		DDLogError(@"FileBrowser: couldn't create file %@", path);
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:[NSString stringWithFormat:@"Couldn't create file \"%@\"", [path lastPathComponent]]
								  message:error.localizedDescription
								  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	return YES;
}

@end
