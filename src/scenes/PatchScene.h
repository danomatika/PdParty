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

/// basic pd patch
/// path is to patch file, requires all event types
@interface PatchScene : Scene

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui;

/// returns true if the given path is an patch file
+ (BOOL)isPatchFile:(NSString *)fullpath;

@end
