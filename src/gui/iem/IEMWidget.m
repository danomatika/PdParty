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

int iemgui_modulo_color(int col);

@implementation IEMWidget

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.labelFontStyle = 0;
		self.labelFontSize = 10;
	}
	return self;
}

- (void)reshape {

	// bounds
	[super reshape];

	// label
	[self reshapeLabel];
}

- (void)reshapeLabel {
	self.label.font = [UIFont fontWithName:[self fontNameFromStyle:self.labelFontStyle] size:self.labelFontSize * self.gui.scaleX];
	[self.label sizeToFit];
	self.label.frame = CGRectMake(
		round(self.originalLabelPos.x * self.gui.scaleX),
		round((self.originalLabelPos.y * self.gui.scaleY) - (self.labelFontSize * 0.5 * self.gui.scaleY)),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setLabelFontStyle:(int)labelFontStyle {
	_labelFontStyle = CLAMP(labelFontStyle, 0, 2); // only 3 styles
}

- (void)setLabelFontSize:(int)labelFontSize {
	_labelFontSize = MAX(labelFontSize, IEM_FONT_MINSIZE); // clamp to min of 4
}

- (NSString *)type {
	return @"IEMWidget";
}

#pragma mark WidgetListener

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"color"] && [arguments count] > 2 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1] && [arguments isNumberAt:2])) {
		// background, front-color, label-color
		self.fillColor = [IEMWidget colorFromEditColor:arguments[0]];
		self.controlColor = [IEMWidget colorFromEditColor:arguments[1]];
		self.label.textColor = [IEMWidget colorFromEditColor:arguments[2]];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"size"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// width, height
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			CLAMP([arguments[0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([arguments[1] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"pos"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// absolute pos
		self.originalFrame = CGRectMake(
			[arguments[0] floatValue], [arguments[1] floatValue],
			CGRectGetWidth(self.originalFrame), CGRectGetHeight(self.originalFrame));
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"delta"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// relative pos
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x + [arguments[0] floatValue],
			self.originalFrame.origin.y + [arguments[1] floatValue],
			CGRectGetWidth(self.originalFrame), CGRectGetHeight(self.originalFrame));
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"label"] && [arguments count] > 0 && [arguments isStringAt:0]) {
		self.label.text = arguments[0];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"label_pos"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// x, y
		self.originalLabelPos = CGPointMake([arguments[0] floatValue],
											[arguments[1] floatValue]);
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"label_font"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		self.labelFontStyle = [arguments[0] intValue];
		self.labelFontSize = [arguments[1] floatValue];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"send"] && [arguments count] > 0 && [arguments isStringAt:0]) {
		self.sendName = arguments[0];
		return YES;
	}
	else if([message isEqualToString:@"receive"] && [arguments count] > 0 && [arguments isStringAt:0]) {
		self.receiveName = arguments[0];
		return YES;
	}
	else if([message isEqualToString:@"init"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		self.inits = [arguments[0] boolValue];
		return YES;
	}
	return NO;
}

#pragma mark Util

- (NSString *)fontNameFromStyle:(int)iemFont {
	switch(iemFont) {
		case 1:
			return @"Helvetica";
		case 2:
			return @"Times";
		default: // 0
			return self.gui.fontName;
	}
}

// from g_all_guis.c colfromatomload()
+ (UIColor *)colorFromAtomColor:(NSString *)color {
	// hex
	if([color characterAtIndex:0] == '#') {
		return [IEMWidget colorFromHexColor:color];
	}
	// old IEM int color
	// from g_all_guis.c colfromatomload()
	int r, g, b, iemColor = [color intValue];
	if(iemColor < 0) { // pre-Pd 0.48 limited resolution
		iemColor = -1 - iemColor;
		r = (iemColor & 0x3F000) >> 10;
		g = (iemColor & 0xFC0)   >> 4;
		b = (iemColor & 0x3F)    << 2;
	}
	else { // Pd 0.48 full resolution
		iemColor = iemgui_modulo_color(iemColor);
		iemColor = iemgui_color_hex[iemColor] << 8 | 0xFF;
		r = ((iemColor >> 24) & 0xFF);
		g = ((iemColor >> 16) & 0xFF);
		b = ((iemColor >> 8)  & 0xFF);
	}
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

+ (UIColor *)colorFromEditColor:(NSString *)color {
	// hex
	if([color characterAtIndex:0] == '#') {
		return [IEMWidget colorFromHexColor:color];
	}

	return [IEMWidget colorFromIntColor:[color intValue]];
}

// old IEM int color
// from g_all_guis.c iemgui_compatible_colorarg()
+ (UIColor *)colorFromIntColor:(int)iemColor {
	int r, g, b;
	if(iemColor < 0) { // pre-Pd 0.48 limited resolution
		iemColor = (-1 - iemColor) & 0xFFFFFF;
		r = (iemColor & 0xFF0000) >> 16;
		g = (iemColor & 0xFF00)   >> 8;
		b = (iemColor & 0xFF)     >> 0;
	}
	else { // Pd 0.48 full resolution
		iemColor = iemgui_modulo_color(iemColor);
		iemColor = iemgui_color_hex[iemColor] << 8 | 0xFF;
		r = ((iemColor >> 24) & 0xFF);
		g = ((iemColor >> 16) & 0xFF);
		b = ((iemColor >> 8)  & 0xFF);
	}
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

// Pd 0.52 hex colors
// from g_all_guis.c iemgui_getcolorarg()
+ (UIColor *)colorFromHexColor:(NSString *)hexColor {
	int r, g, b;
	NSString *c = [hexColor substringFromIndex:1];
	int color = ((int)strtol(c.UTF8String, 0, 16)) & 0xFFFFFF;
	r = ((color >> 16) & 0xFF);
	g = ((color >> 8)  & 0xFF);
	b = (color         & 0xFF);
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

@end
