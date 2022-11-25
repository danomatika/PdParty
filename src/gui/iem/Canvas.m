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
#import "Canvas.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@implementation Canvas

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 18) { // sanity check
		DDLogWarn(@"Canvas: cannot create, atom line length < 18");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.labelFontSize = 14;

		self.sendName = [Gui filterEmptyStringValues:line[8]];
		self.receiveName = [Gui filterEmptyStringValues:line[9]];
		// don't check receiveName as canvas could be a simple background component, etc
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[6] floatValue], [line[7] floatValue]);
		
		self.label.text = [Gui filterEmptyStringValues:line[10]];
		self.originalLabelPos = CGPointMake([line[11] floatValue], [line[12] floatValue]);
		self.labelFontStyle = [line[13] intValue];
		self.labelFontSize = [line[14] floatValue];
		
		self.backgroundColor = [IEMWidget colorFromAtomColor:line[15]];
		self.label.textColor = [IEMWidget colorFromAtomColor:line[16]];
	}
	return self;
}

// override for custom redraw
- (void)reshape {
	// bounds, scale by true horz AND vert scaling as this looks better at bad aspect ratios/orientations
	self.frame = CGRectMake(
		round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
		round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleX),
		round(self.originalFrame.size.height * self.gui.scaleY));

	// label
	[self reshapeLabel];
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Canvas";
}

#pragma mark WidgetListener

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"color"] && [arguments count] > 1) {
		// background, label-color
		self.backgroundColor = [IEMWidget colorFromEditColor:arguments[0]];
		self.label.textColor = [IEMWidget colorFromEditColor:arguments[1]];
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"size"]) {
		// selectable object size, ignored here since we don't support editing patches
		DDLogWarn(@"%@: ignoring size edit message", self.type);
	}
	else if([message isEqualToString:@"vis_size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// canvas size: width, height
		float w = MAX([arguments[0] floatValue], 1);
		float h = CGRectGetHeight(self.originalFrame);
		if([arguments count] > 1 && [arguments isNumberAt:1]) {
			h = MAX([arguments[1] floatValue], 1);
		}
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y, w, h);
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"get_pos"]) {
		// send pos
		[self sendList:@[
			@(self.originalFrame.origin.x),
			@(self.originalFrame.origin.y)
		]];
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return YES;
}

@end

#pragma mark - ViewPortCanvas

@implementation ViewPortCanvas

// FIXME: this ends up calling reshape on the cnv twice
- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	BOOL ret = [super receiveEditMessage:message withArguments:arguments];
	if([message isEqualToString:@"pos"]) {
		DDLogInfo(@"ViewPortCanvas: pos %g %g", self.originalFrame.origin.x, self.originalFrame.origin.y);
		if(self.delegate) {
			[self.delegate receivePositionX:self.originalFrame.origin.x Y:self.originalFrame.origin.y];
		}
	}
	else if([message isEqualToString:@"vis_size"]) {
		DDLogInfo(@"ViewPortCanvas: vis_size %g %g", self.originalFrame.size.width, self.originalFrame.size.height);
		if(self.delegate) {
			[self.delegate receiveSizeW:self.originalFrame.size.width H:self.originalFrame.size.height];
		}
	}
	return ret;
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"ViewPortCanvas";
}

@end
