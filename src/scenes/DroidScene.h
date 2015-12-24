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

// DroidParty scene (folder with droidparty_main.pd), landscape only
@interface DroidScene : PatchScene

// path is to scene folder

@property (strong, nonatomic) UIImageView *background;

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui;

// returns true if a given path is a DroidParty scene dir
+ (BOOL)isDroidPartyDirectory:(NSString *)fullpath;

@end
