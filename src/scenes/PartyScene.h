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
#import "PatchScene.h"

/// PdParty scene (folder with _main.pd)
/// path is to scene folder
@interface PartyScene : PatchScene

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui;

/// returns true if the given path is a PdParty scene dir
+ (BOOL)isPdPartyDirectory:(NSString *)fullpath;

/// returns a dictionary loaded from the info.json or Info.json in a given scene dir,
/// returns nil if not found or is empty
+ (NSDictionary*)infoForSceneAt:(NSString *)fullpath;

@end
