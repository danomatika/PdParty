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

+ (id)canvasFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Canvas: Cannot create, atom line length < 18");
		return nil;
	}

	Canvas *c = [[Canvas alloc] initWithFrame:CGRectZero];

	c.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	c.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
	// don't check receiveName as canvas could be a simple background component, etc
	
	c.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:6] floatValue], [[line objectAtIndex:7] floatValue]);
	
	c.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
	c.originalLabelPos = CGPointMake([[line objectAtIndex:11] floatValue], [[line objectAtIndex:12] floatValue]);
	c.labelFontSize = [[line objectAtIndex:14] floatValue];
	
	c.backgroundColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	c.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	
	[c reshapeForGui:gui];
	c.gui = gui;
	
	return c;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.labelFontSize = 14;
    }
    return self;
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
		[self reshapeForGui:self.gui];
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
			h = MAX([[arguments objectAtIndex:0] floatValue], 1);
		}
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y, w, h);
		[self reshapeForGui:self.gui];
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
