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

#import "NowPlayingTableViewController.h"
#import "PartyBrowser.h"

@class PatchViewController;

/// main MasterViewController for browsing the Documents dir
@interface BrowserViewController : PartyBrowser <BrowserDelegate>

/// strong to make sure to retain the view on iPhone
@property (strong, nonatomic) PatchViewController *patchViewController;

/// load the default Documents dir
/// returns YES on success
- (BOOL)loadDocumentsDirectory;

/// open a path in the PatchViewController or in the browser itself,
/// requires full path within the Documents dir
/// pushes browser layers onto the stack starting in the Documents dir
/// returns YES on success
- (BOOL)openPath:(NSString *)path;

/// unzip a path to a given directory & delete original zip file
/// if decompression succeeded
/// returns YES on success
+ (BOOL)unzipPath:(NSString *)path toDirectory:(NSString *)directory;

@end
