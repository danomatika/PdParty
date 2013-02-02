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
#import "Canvas.h"

#import "Gui.h"

@implementation Canvas

+ (id)canvasFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Cannot create Canvas, atom line length < 18");
		return nil;
	}

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round([[line objectAtIndex:6] floatValue] * gui.scaleX),
		round([[line objectAtIndex:7] floatValue] * gui.scaleX));

	Canvas *c = [[Canvas alloc] initWithFrame:frame];

	//c.sendName = [gui formatAtomString:[line objectAtIndex:8]];
	c.receiveName = [gui formatAtomString:[line objectAtIndex:9]];
	if(![c hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Dropping Canvas, receive name is empty");
		return nil;
	}
	
	c.backgroundColor = [Gui colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	NSLog(@"Color is %@", c.backgroundColor);
	
	c.label.text = [gui formatAtomString:[line objectAtIndex:10]];
	if(![c.label.text isEqualToString:@""]) {
		c.label.font = [UIFont systemFontOfSize:gui.fontSize];
		[c.label sizeToFit];
		CGRect labelFrame = CGRectMake(
			round([[line objectAtIndex:11] floatValue] * gui.scaleX),
			round(([[line objectAtIndex:12] floatValue] * gui.scaleY) - gui.fontSize),
			c.label.frame.size.width,
			c.label.frame.size.height
		);
		c.label.frame = labelFrame;
		[c addSubview:c.label];
	}
	
	return c;
}

#pragma mark Overridden Getters & Setters

- (NSString*)type {
	return @"Canvas";
}

@end
