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
#import "Widget.h"
#import "Browser.h"

@interface Menubang : Widget

/// name from first argument, used for send name & menu button text if imagePath is nil
@property (strong, nonatomic) NSString *name;

/// optional path to menu button image (default nil)
@property (strong, nonatomic) NSString *imagePath;

#pragma mark Static Access

/// currently loaded menu bangs
+ (NSArray *)menubangs;

/// number of currently loaded menu bangs
+ (int)menubangCount;

@end
