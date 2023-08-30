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
#import "Scene.h"
#import "Canvas.h"

/// basic pd patch
/// path is to patch file, requires all event types
@interface PatchScene : Scene <ViewPortDelegate>

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui;

/// returns YES if the given path is an patch file
+ (BOOL)isPatchFile:(NSString *)fullpath;

#pragma mark Font

/// loaded custom font, if one
@property (strong, nonatomic) NSString *fontPath;

/// load custom GUI font, replaces default pd gui font
/// note: only works on scene load, not dynamically
- (BOOL)loadFont:(NSString *)fontPath;

/// clear custom font
- (void)clearFont;

@end
