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
#import "RjWidget.h"

/// rj_image
@interface RjImage : RjWidget

@property (strong, nonatomic) UIImageView *image; ///< image to draw

@property (assign, nonatomic) float scaleX; ///< current horz size (default 1.0)
@property (assign, nonatomic) float scaleY; ///< current vert size (default 1.0)
@property (assign, nonatomic) float angle; ///< current rotational angle in degrees (default 0)

+ (id)imageWithFile:(NSString *)path andParent:(RjScene *)parent;

/// set current scale (default 1.0 & 1.0)
- (void)setScaleX:(float)sx andY:(float)sy;

@end
