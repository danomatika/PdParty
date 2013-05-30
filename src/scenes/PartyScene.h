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

// PdParty scene (folder with _main.pd)
@interface PartyScene : PatchScene

+ (id)sceneWithParent:(UIView*)parent andGui:(Gui*)gui;;

// returns true if the given path is a PdParty scene dir
+ (BOOL)isPdPartyDirectory:(NSString *)fullpath;

@end
