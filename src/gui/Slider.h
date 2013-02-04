/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#import "Widget.h"

@class Gui;

typedef enum {
	SliderOrientationHorizontal,
	SliderOrientationVertical
} SliderOrientation;

@interface Slider : Widget

@property (assign) int log;
@property (assign) SliderOrientation orientation;

+ (id)sliderFromAtomLine:(NSArray*)line withOrientation:(SliderOrientation)orientation withGui:(Gui*)gui;

@end
