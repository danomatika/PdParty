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

// rj_text
@interface RjText : RjWidget

@property (assign, nonatomic) NSString *text;
@property (assign, nonatomic) float size;

@property (strong, nonatomic) UILabel *label;

+ (id)imageWithText:(NSString *)text andParent:(RjScene *)parent;

@end
