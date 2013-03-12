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

@implementation Canvas

+ (id)canvasFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Canvas: Cannot create, atom line length < 18");
		return nil;
	}

	Canvas *c = [[Canvas alloc] initWithFrame:CGRectZero];

	c.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]]; // not really used, but we'll load it anyway
	c.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
	// don't check receiveName as canvas could bea simple background component, etc
	
	c.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:6] floatValue], [[line objectAtIndex:7] floatValue]);
	
	c.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
	c.originalLabelPos = CGPointMake([[line objectAtIndex:11] floatValue], [[line objectAtIndex:12] floatValue]);
	c.labelFontSize = [[line objectAtIndex:14] floatValue];
	
	c.backgroundColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	c.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	
	[c reshapeForGui:gui];
	
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

@end
