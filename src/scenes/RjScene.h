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

@class ControlsView;

// an RjDj scene (folder with .rj ext & _main.pd)
@interface RjScene : PatchScene <PdListener>

// path is to scene folder

@property (weak, nonatomic) PdDispatcher *dispatcher;
@property (weak, nonatomic) ControlsView *controlsView;

@property (strong, nonatomic) UIImageView *background;

// scale amount between background bounds and background pixel size
@property (assign, readonly, nonatomic) float scale;

+ (id)sceneWithParent:(UIView *)parent andDispatcher:(PdDispatcher *)dispatcher;

// returns true if the given path is an RjDj scene dir
+ (BOOL)isRjDjDirectory:(NSString *)fullpath;

@end
