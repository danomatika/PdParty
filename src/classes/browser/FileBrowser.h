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
#import "FileBrowserLayer.h"

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

/// drill-down file browser with basic editing functions: move, rename, & delete
/// pushes multiple layer onto a nav controller automatically
@interface FileBrowser : FileBrowserLayer

/// receive selection events
/// this value is shared by the root layer to all pushed layers
@property (assign, nonatomic) id<FileBrowserDelegate> delegate;

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

/// create full file path, shows dialog on overwrite
- (BOOL)createFilePath:(NSString *)file;

/// create full directory path
- (BOOL)createDirectoryPath:(NSString *)dir;

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

/// returns YES if the given path has one of the allowed file extensions,
/// also returns NO if extensions are not set
- (BOOL)pathHasAllowedExtension:(NSString *)path;

@end
