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

@class Browser;

/// browser modes
typedef enum {
	BrowserModeBrowse,
	BrowserModeEdit,
	BrowserModeMove
} BrowserMode;

/// single drill-down file browser layer with basic editing functions: move,
/// rename, & delete
///
/// note: clears paths & table cells when going out of view to save memory
///
/// do not use directly, use Browser instead
@interface BrowserLayer : UITableViewController

/// current browser mode (default: BrowserModeBrowse)
@property (assign, nonatomic) BrowserMode mode;

/// current top layer directory path (default: Documents)
@property (readonly, nonatomic) NSString *directory;

/// table view paths in the current dir
@property (readonly, nonatomic) NSMutableArray *paths;

/// set a custom navigation bar title, (default: current dir name)
@property (copy, nonatomic) NSString *title;

// root browser layer or self if a single layer, this must be set to a valid object
@property (nonatomic) Browser *root;

#pragma mark Location

/// change to and load a new current dir
- (void)loadDirectory:(NSString *)dirPath;

/// reload the current directory
- (void)reloadDirectory;

// clar current paths & cells
- (void)unloadDirectory;

/// clear current directory, paths, & cells
- (void)clearDirectory;

#pragma mark Subclassing

/// setup resources during init, make sure to call [super setup] if overriding
- (void)setup;

@end
