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
#import <UIKit/UIKit.h>

@class FileBrowser;

/// file browser modes
typedef enum {
	FileBrowserModeBrowse,
	FileBrowserModeEdit,
	FileBrowserModeMove
} FileBrowserMode;

/// single drill-down file browser layer with basic editing functions: move,
/// rename, & delete
/// do not use directly, use FileBrowser instead
@interface FileBrowserLayer : UITableViewController

/// current browser mode (default: FileBrowserModeBrowse)
@property (assign, nonatomic) FileBrowserMode mode;

/// current top layer directory path (default: Documents)
@property (readonly, nonatomic) NSString *directory;

/// table view paths in the current dir
@property (readonly, nonatomic) NSMutableArray *paths;

/// set a custom navigation bar title, (default: current dir name)
@property (copy, nonatomic) NSString *title;

// root browser layer or self if a single layer
@property (nonatomic) FileBrowser *root;

#pragma mark Location

/// change to and load a new current dir
- (void)loadDirectory:(NSString *)dirPath;

/// reload the current directory
- (void)reloadDirectory;

/// clear current directory and paths
- (void)clearDirectory;

#pragma mark Subclassing

/// setup resources during init, make sure to call [super setup] if overriding
- (void)setup;

/// creates the Cancel button in browse mode, override to provide a custom button
/// uses target:self action:@selector(cancelButtonPressed)
- (UIBarButtonItem *)browsingModeRightBarItem;

/// used to determine whether to add a path to the browser, override to filter out
/// unwanted path names or types
- (BOOL)shouldAddPath:(NSString *)path isDir:(BOOL)isDir;

/// stylizes default table view cell for a given path, override to customize cell
/// with file icons, etc for certain paths
- (void)styleCell:(UITableViewCell *)cell forPath:(NSString *)path isDir:(BOOL)isDir;

@end
