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
#import "IEMWidget.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@implementation IEMWidget

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.labelFontSize = 10;
    }
    return self;
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];

	// label
	[self reshapeLabelForGui:gui];
}

- (void)reshapeLabelForGui:(Gui *)gui {
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:self.labelFontSize * gui.scaleX];
	[self.label sizeToFit];
	self.label.frame = CGRectMake(
		round(self.originalLabelPos.x * gui.scaleX),
		round((self.originalLabelPos.y * gui.scaleY) - (self.labelFontSize * 0.5 * gui.scaleX)),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setLabelFontSize:(int)labelFontSize {
	_labelFontSize = MAX(labelFontSize, IEM_FONT_MINSIZE); // clamp to min of 4
}

- (NSString *)type {
	return @"IEMWidget";
}

#pragma mark Util

+ (UIColor *)colorFromIEMColor:(int)iemColor {
	int r, g, b;
	if(iemColor < 0) {
		iemColor = -1 - iemColor;
		r = (iemColor & 0x3F000) >> 10;
		g = (iemColor & 0xFC0) >> 4;
		b = (iemColor & 0x3F) << 2;
	}
	else {
		iemColor = iemgui_modulo_color(iemColor);
		iemColor = iemgui_color_hex[iemColor] << 8 | 0xFF;
		r = ((iemColor >> 24) & 0xFF);
		g = ((iemColor >> 16 ) & 0xFF);
		b = ((iemColor >> 8) & 0xFF);
	}
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

@end
