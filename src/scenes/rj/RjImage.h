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

// rj_image
@interface RjImage : RjWidget

@property (strong, nonatomic) UIImageView *image;

@property (assign, nonatomic) float scaleX;
@property (assign, nonatomic) float scaleY;
@property (assign, nonatomic) float angle;

+ (id)imageWithFile:(NSString *)path andParent:(RjScene *)parent;

- (void)setScaleX:(float)sx andY:(float)sy;

@end
