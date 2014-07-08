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

// an RjDj scene (folder with .rj ext & _main.pd)
@interface RjScene : PatchScene <PdListener>

// path is to scene folder

@property (weak, nonatomic) PdDispatcher *dispatcher;

@property (strong, nonatomic) UIImageView *background;

// scale amount between background bounds and background pixel size
@property (assign, readonly, nonatomic) float scale;

+ (id)sceneWithParent:(UIView *)parent andDispatcher:(PdDispatcher *)dispatcher;

// returns true if the given path is an RjDj scene dir
+ (BOOL)isRjDjDirectory:(NSString *)fullpath;

// returns a thumbnail.jpg for a given RjDj scene dir, falls back to image.jpg
// return nil if images not found
+ (UIImage*)thumbnailForSceneAt:(NSString *)fullpath;

// returns a dictionary loaded from the Info.plist in a given RjDj scene dir,
// returns nil if Info.plist is not found or is empty
+ (NSDictionary*)infoForSceneAt:(NSString *)fullpath;

@end
