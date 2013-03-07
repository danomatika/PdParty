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
#import "Comment.h"

#import "Gui.h"

@implementation Comment

+ (id)commentFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 4) { // sanity check
		DDLogWarn(@"Cannot create Comment, atom line length < 4");
		return nil;
	}

	Comment *c = [[Comment alloc] initWithFrame:CGRectZero];

	c.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on label size

	// create the comment string
	NSMutableString *text = [[NSMutableString alloc] init];
	for(int i = 4; i < line.count; ++i) {
		[text appendString:[line objectAtIndex:i]];
		if(i < line.count - 1) {
			[text appendString:@" "];
		}
	}
	c.label.text = text;

	[c reshapeForGui:gui];
	
	return c;
}

- (void)reshapeForGui:(Gui *)gui {

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	self.label.numberOfLines = 0;
	self.label.preferredMaxLayoutWidth = gui.fontSize * GUI_LINE_WRAP;
	[self.label sizeToFit];

	// bounds based on computed label size
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (NSString*)type {
	return @"Comment";
}

@end
