/*
 * Copyright (c) 2014 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * References for an iOS "drilldown" table view browser:
 *   - http://www.iphonesdkarticles.com/2009/03/uitableview-drill-down-table-view.html
 *   - http://stackoverflow.com/questions/8683141/drill-down-tableview-in-storyboards
 *   - http://stackoverflow.com/questions/8848857/how-do-i-change-initwithnibname-in-storyboard
 */
#import "BrowserLayer.h"

@class Browser;

/// file browser event delegate
@protocol BrowserDelegate <NSObject>

/// full file path selected
- (void)browser:(Browser *)browser selectedFile:(NSString *)path;

@optional

/// full directory path selected, return YES to push new layer or NO if handling
/// path manually
- (BOOL)browser:(Browser *)browser selectedDirectory:(NSString *)path;

/// the browser has been canceled and just disappeared
- (void)browserCancel:(Browser *)browser;

/// file path has been created
- (void)browser:(Browser *)browser createdFile:(NSString *)path;

/// directory path has been created
- (void)browser:(Browser *)browser createdDirectory:(NSString *)path;

@end

/// file browser data delegate
@protocol BrowserDataDelegate <NSObject>

/// used to determine whether to add a path to the browser, override to filter out
/// unwanted path names or types
- (BOOL)browser:(Browser *)browser shouldAddPath:(NSString *)path isDir:(BOOL)isDir;

/// used to determine whether a given path is selectable in the browser, override
// disable selection for certain types of paths
- (BOOL)browser:(Browser *)browser isPathSelectable:(NSString *)path isDir:(BOOL)isDir;

/// stylizes default table view cell for a given path
///
/// sets cell text to lastpath component, grey text for non selectable cells,
/// and disclosure indicator for directories
///
/// override to customize cell with file icons, etc for certain paths
- (void)browser:(Browser *)browser styleCell:(UITableViewCell *)cell
                                     forPath:(NSString *)path
                                       isDir:(BOOL)isDir
                                isSelectable:(BOOL)isSelectable;

@end

/// drill-down file browser with basic editing functions: move, rename, & delete
/// pushes multiple layers onto a nav controller automatically
@interface Browser : BrowserLayer <BrowserDataDelegate>

/// receive selection events
/// this value is shared by the root layer to all pushed layers
@property (assign, nonatomic) id<BrowserDelegate> delegate;

/// choose paths & stylize cells
/// this value is shared by the root layer to all pushed layers
/// should not be nil
@property (assign, nonatomic) id<BrowserDataDelegate> dataDelegate;

/// required file extensions (w/out period), leave nil to allow all (default: nil)
/// if only 1 file extension is set, automatically appends extension in new file
/// and rename dialogs
/// this value is shared by the root layer to all pushed layers
@property (strong, nonatomic) NSArray *extensions;

/// ignore files & only show directories? (default: NO)
@property (nonatomic) BOOL directoriesOnly;

/// show the "Edit" button in browse mode? (default: YES)
@property (assign, nonatomic) BOOL showEditButton;

/// show the "Move..." button in edit mode? (default: YES)
@property (assign, nonatomic) BOOL showMoveButton;

/// can the current directory be selected via a "Choose Folder" button? (default: NO)
/// only used in Browse mode with directoriesOnly = YES
@property (assign, nonatomic) BOOL canSelectDirectories;

/// can add files from plus button Add Sheet? (default: YES)
@property (assign, nonatomic) BOOL canAddFiles;

/// can add dirs from plus button Add Sheet? (default: YES)
@property (assign, nonatomic) BOOL canAddDirectories;

// returns YES if the current layer is at the root directory
/// aka topViewController == self
@property (readonly, nonatomic) BOOL isRootLayer;

#pragma mark Present

/// presents the browser in a navigation controller from the current key window,
/// creates nav controller if not set
- (void)presentAnimated:(BOOL)animated;

/// presents the browser in a navigation controller from a given view controller,
/// creates nav controller if not set
- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated;

#pragma mark Location

/// change to and load a new current dir, clears any currently pushed layers
/// returns YES on success
- (BOOL)loadDirectory:(NSString *)dirPath;

/// change to and load a new current dir which is a child of a given base dir,
/// pushes layers from basePath to dirPath & creates nav controller if not set
/// returns YES on success
- (BOOL)loadDirectory:(NSString *)dirPath relativeTo:(NSString *)basePath;

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
- (void)showRenameDialogForPath:(NSString *)path completion:(void (^)(void))completion;

#pragma mark Utils

/// create full file path, shows dialog on overwrite
- (BOOL)createFilePath:(NSString *)file;

/// create full directory path
- (BOOL)createDirectoryPath:(NSString *)dir;

/// rename full path
- (BOOL)renamePath:(NSString *)path to:(NSString *)newPath
        completion:(void (^)(BOOL failed))completion;

/// copy path to a new directory
- (BOOL)copyPath:(NSString *)path toDirectory:(NSString *)newDir
      completion:(void (^)(BOOL failed))completion;

/// move path to a new directory
- (BOOL)movePath:(NSString *)path toDirectory:(NSString *)newDir
      completion:(void (^)(BOOL failed))completion;

/// delete full path
- (BOOL)deletePath:(NSString *)path
        completion:(void (^)(BOOL failed))completion;

/// get the number of files for the current file extensions
- (unsigned int)fileCountForExtensions;

/// get the number of files for a file extension
- (unsigned int)fileCountForExtension:(NSString *)extension;

/// returns YES if the given path has one of the allowed file extensions,
/// also returns NO if extensions are not set
- (BOOL)pathHasAllowedExtension:(NSString *)path;

#pragma mark Subclassing

/// creates the Cancel button in browse mode, override to provide a custom button
/// uses target:layer action:@selector(cancelButtonPressed)
- (UIBarButtonItem *)browsingModeRightBarItemForLayer:(BrowserLayer *)layer;

/// creates a new Browser with the current table view style,
/// used in BrowserLayer to create Move browser
- (Browser *)newBrowser;

@end
