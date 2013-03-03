/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

@class PatchViewController;

// main MasterViewController for browsing the Documents dir
@interface BrowserViewController : UITableViewController

@property (strong, nonatomic) PatchViewController *patchViewController;

@property (strong) NSMutableArray *pathArray; // table view paths
@property (strong) NSString *currentDir; // current directory path

// change to and load a new current dir
- (void)loadDirectory:(NSString *)dirPath;

@end
