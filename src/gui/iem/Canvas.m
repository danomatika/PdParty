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

	//c.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	c.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
//	if(![c hasValidReceiveName]) {
//		// drop something we can't interact with
//		DDLogVerbose(@"Canvas: Dropping, receive name is empty");
//		return nil;
//	}
	
	c.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:6] floatValue], [[line objectAtIndex:7] floatValue]);
	
	c.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
	c.originalLabelPos = CGPointMake([[line objectAtIndex:11] floatValue], [[line objectAtIndex:12] floatValue]);
	c.labelFontSize = [[line objectAtIndex:14] floatValue];
	
	c.backgroundColor = [Gui colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	c.label.textColor = [Gui colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	
	[c reshapeForGui:gui];
	
	return c;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if (self) {
		self.labelFontSize = 14;
    }
    return self;
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:self.labelFontSize * gui.scaleX];
	[self.label sizeToFit];
	self.label.frame  = CGRectMake(
		round(self.originalLabelPos.x * gui.scaleX),
		round((self.originalLabelPos.y * gui.scaleY) - (self.labelFontSize * gui.scaleX * 0.75)),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Canvas";
}

@end
