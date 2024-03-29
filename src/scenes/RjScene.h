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

/// an RjDj scene (folder with .rj ext & _main.pd), portrait only
/// path is to scene folder, square background image (nominally 320x320)
@interface RjScene : PatchScene <PdListener>

/// dispatcher to receive rj_image & rj_text pd events
@property (weak, nonatomic) PdDispatcher *dispatcher;

/// scale amount between background bounds and background pixel size
@property (assign, readonly, nonatomic) float scale;

+ (id)sceneWithParent:(UIView *)parent andDispatcher:(PdDispatcher *)dispatcher;

/// returns YES if the given path is an RjDj scene dir
+ (BOOL)isRjDjDirectory:(NSString *)fullpath;

/// returns a thumbnail.jpg for a given RjDj scene dir, falls back to image.jpg
/// return nil if images not found
+ (UIImage *)thumbnailForSceneAt:(NSString *)fullpath;

/// returns a dictionary loaded from the Info.plist or info.plist in a given RjDj scene dir,
/// returns nil if not found or is empty
+ (NSDictionary *)infoForSceneAt:(NSString *)fullpath;

@end
