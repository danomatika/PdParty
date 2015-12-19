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
#import "FileBrowser.h"

/// drill-down file browser with icons for pd party types
@interface Browser : FileBrowser

#pragma mark Utils

// is the given file path a zip file?
+ (BOOL)isZipFile:(NSString *)path;

@end
