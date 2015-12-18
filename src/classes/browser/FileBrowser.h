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

#import <UIKit/UIKit.h>

@class FileBrowser;

/// file browser event delegate
@protocol FileBrowserDelegate <NSObject>
- (void)fileBrowser:(FileBrowser *)browser selectedFile:(NSString *)path;
@optional
- (void)fileBrowser:(FileBrowser *)browser selectedDirectory:(NSString *)path;
- (void)fileBrowserCancel:(FileBrowser *)browser;
- (void)fileBrowser:(FileBrowser *)browser createdFile:(NSString *)path;
- (void)fileBrowser:(FileBrowser *)browser createdDirectory:(NSString *)path;
@end

/// file browser modes
typedef enum {
	FileBrowserModeBrowse,
	FileBrowserModeEdit,
	FileBrowserModeMove
} FileBrowserMode;

/// drill-down file browser with basic editing functions: move, rename, & delete
///
/// pushes multiple layer onto a nav controller automatically, use the top &
/// root properties to access key layers as the FileBrowser instance itself
/// may not refer to the current top layer being displayed
///
@interface FileBrowser : UITableViewController

/// receive selection events
/// this value is shared by the root layer to all pushed layers
@property (assign, nonatomic) id<FileBrowserDelegate> delegate;

/// current browser mode (default: FileBrowserModeBrowse)
@property (readonly, nonatomic) FileBrowserMode mode;

/// current directory path (default: Documents)
@property (strong, readonly, nonatomic) NSString *currentDir;

/// table view paths in the current dir
@property (strong, readonly, nonatomic) NSMutableArray *paths;

/// required file extensions (w/out period), leave nil to allow all (default: nil)
/// if only 1 file extension is set, automatically appends extension in new file
/// and rename dialogs
/// this value is shared by the root layer to all pushed layers
@property (strong, nonatomic) NSArray *extensions;

/// ignore files & only show directories? (default: NO)
@property (nonatomic) BOOL directoriesOnly;

/// show the "Edit" button in browse mode? (default: YES)
@property (assign, nonatomic) BOOL showEditButton;

/// show the "Move" button in edit mode? (default: YES)
@property (assign, nonatomic) BOOL showMoveButton;

/// can the current directory be selected via a "Choose Folder" button? (default: NO)
/// only used in Browse mode with directoriesOnly = YES
@property (assign, nonatomic) BOOL canSelectDirectories;

/// can add files from plus button Add Sheet? (default: YES)
@property (assign, nonatomic) BOOL canAddFiles;

/// can add dirs from plus button Add Sheet? (default: YES)
@property (assign, nonatomic) BOOL canAddDirectories;

/// set a custom navigation bar title, (default: current dir name)
@property (copy, nonatomic) NSString *title;

/// root browser layer or self if a single layer
@property (readonly, nonatomic) FileBrowser *root;

/// browser top layer or self if a single layer
@property (readonly, nonatomic) FileBrowser *top;

#pragma mark Present

/// presents the browser in a navigation controller from the current key window,
/// creates nav controller if not set
- (void)presentAnimated:(BOOL)animated;

/// presents the browser in a navigation controller from a given view controller,
/// creates nav controller if not set
- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated;

#pragma mark Location

/// change to and load a new current dir, clears any currently pushed layers
- (void)loadDirectory:(NSString *)dirPath;

/// change to and load a new current dir which is a child of a given base dir,
/// pushes layers from basePath to dirPath & creates nav controller if not set
/// use root & top properties to access root & top browser layers
- (void)loadDirectory:(NSString *)dirPath relativeTo:(NSString *)basePath;

/// reload the current directory
- (void)reloadDirectory;

/// unload the current directory, clears paths but not currentDir
- (void)unloadDirectory;

/// clear current directory and paths
- (void)clearDirectory;

#pragma mark Dialogs

/// show new file dialog manually, uses file extensions if set
/// if only 1 file extension is set, automatically appends extension
- (void)showNewFileDialog;

/// show new directory dialog manually
- (void)showNewDirectoryDialog;

/// show rename dialog manually, uses file extensions if set
/// if only 1 file extension is set, automatically appends extension when
/// renaming files
- (void)showRenameDialogForPath:(NSString *)path;

#pragma mark Utils

/// create file at the current location
- (BOOL)createFile:(NSString *)file;

/// create directory at the current location
- (BOOL)createDirectory:(NSString *)dir;

/// rename full path
- (BOOL)renamePath:(NSString *)path to:(NSString *)newPath;

/// move path to a new directory
- (BOOL)movePath:(NSString *)path toDirectory:(NSString *)newDir;

/// delete full path
- (BOOL)deletePath:(NSString *)path;

/// get the number of files for the current file extensions
- (unsigned int)fileCountForExtensions;

/// get the number of files for a file extension
- (unsigned int)fileCountForExtension:(NSString *)extension;

#pragma mark Subclassing

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
