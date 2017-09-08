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

		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
		// don't check receiveName as canvas could be a simple background component, etc
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:6] floatValue], [[line objectAtIndex:7] floatValue]);
		
		self.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
		self.originalLabelPos = CGPointMake([[line objectAtIndex:11] floatValue], [[line objectAtIndex:12] floatValue]);
		self.labelFontStyle = [[line objectAtIndex:13] intValue];
		self.labelFontSize = [[line objectAtIndex:14] floatValue];
		
		self.backgroundColor = [IEMWidget colorFromAtomColor:[[line objectAtIndex:15] intValue]];
		self.label.textColor = [IEMWidget colorFromAtomColor:[[line objectAtIndex:16] intValue]];
	}
	return self;
}

// override for custom redraw
- (void)reshape {

	// bounds, scale by true horz AND vert scaling as this looks better at bad aspect ratios/orientations
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * self.gui.scaleX),
		round(self.originalFrame.origin.y * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleX),
		round(self.originalFrame.size.height * self.gui.scaleY));

	// label
	[self reshapeLabel];
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Canvas";
}

#pragma mark WidgetListener

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"color"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// background, label-color
		self.backgroundColor = [IEMWidget colorFromIEMColor:[[arguments objectAtIndex:0] intValue]];
		self.label.textColor = [IEMWidget colorFromIEMColor:[[arguments objectAtIndex:1] intValue]];
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"size"]) {
		// selectable object size, ignored here since we don't support editing patches
		DDLogWarn(@"%@: ignoring size edit message", self.type);
	}
	else if([message isEqualToString:@"vis_size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// canvas size: width, height
		float w = MAX([[arguments objectAtIndex:0] floatValue], 1);
		float h = CGRectGetHeight(self.originalFrame);
		if([arguments count] > 1 && [arguments isNumberAt:1]) {
			h = MAX([[arguments objectAtIndex:1] floatValue], 1);
		}
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y, w, h);
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"get_pos"]) {
		// send pos
		[self sendList:[NSArray arrayWithObjects:
			[NSNumber numberWithFloat:self.originalFrame.origin.x],
			[NSNumber numberWithFloat:self.originalFrame.origin.y], nil]];
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return YES;
}

@end
