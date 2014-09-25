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
#import "FileBrowserCell.h"

typedef enum {
	FileBrowserModeNone,
	FileBrowserModeBrowse,
	FileBrowserModeEdit,
	FileBrowserModeMove
} FileBrowserMode;

@class FileBrowser;

typedef void (^FileBrowserBlock) (FileBrowser *fileBrowser);
typedef void (^FileBrowserSelectionBlock) (FileBrowser *fileBrowser, NSString *selection);
//typedef void (^FileBrowserCompletionBlock) (FileBrowser *fileBrowser, BOOL can);

@interface FileBrowser : UITableViewController <SWTableViewCellDelegate>

@property (strong, readonly, nonatomic) NSMutableArray *pathArray; // table view paths
@property (strong, readonly, nonatomic) NSString *currentDir; // current directory path
@property (assign, readonly, nonatomic) int currentDirLevel; // currently dir depth relative to Documents

@property (strong, nonatomic) NSString *extension; // required file extension, leave nil to allow all
@property (nonatomic) BOOL directoriesOnly; // ignore files & only show directories?

// browser action blocks, instead of what would be a cumbersome delegate in this case
@property (copy, nonatomic) FileBrowserBlock didCreateFileBlock;
@property (copy, nonatomic) FileBrowserBlock didCreateFolderBlock;
@property (copy, nonatomic) FileBrowserBlock didRenameBlock;
@property (copy, nonatomic) FileBrowserBlock didMoveBlock;
@property (copy, nonatomic) FileBrowserBlock didDeleteBlock; // called after both single & multi delete
@property (copy, nonatomic) FileBrowserSelectionBlock didSelectFile;
@property (copy, nonatomic) FileBrowserSelectionBlock didSelectFolder;
//@property (copy, nonatomic) FileBrowserBlock didCancelBlock; // called after
//@property (copy, nonatomic) FileBrowserBlock didDismissBlock; // called after view is dismissed by browser cancel button

@property (readonly, nonatomic) FileBrowserMode mode; // current browser mode (default: browsing)

#pragma mark Location

// change to and load a new current dir
- (void)loadDirectory:(NSString *)dirPath;

// reload the current directory
- (void)reloadDirectory;

// unload the current directory, does not clear currentDir
- (void)unloadDirectory;

#pragma mark Utils

// create file at the current location
- (BOOL)createFile:(NSString *)file;

// create folder at the current location
- (BOOL)createFolder:(NSString *)folder;

// rename full path
- (BOOL)renamePath:(NSString *)path to:(NSString *)newPath;

// move path to a new folder
- (BOOL)movePath:(NSString *)path toFolder:(NSString *)newFolder;

// delete full path
- (BOOL)deletePath:(NSString *)path;

#pragma mark Subclassing

//
- (UIBarButtonItem *)browsingModeRightBarItem;

@end
