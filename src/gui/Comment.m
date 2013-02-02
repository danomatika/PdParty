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
#import "Comment.h"

#import "Gui.h"

@implementation Comment

+ (id)commentFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 4) { // sanity check
		DDLogWarn(@"Cannot create Comment, atom line length < 4");
		return nil;
	}

	// create the comment string
	NSMutableString *text = [[NSMutableString alloc] init];
	for(int i = 4; i < line.count; ++i) {
		[text appendString:[line objectAtIndex:i]];
		if(i < line.count - 1) {
			[text appendString:@" "];
		}
	}
	
	// create label and size to fit based on pd gui's line wrap at 60 chars
	UILabel *label = [[UILabel alloc] init];
	label.text = text;
	label.font = [UIFont systemFontOfSize:gui.fontSize];
	label.numberOfLines = 0; // allow line wrapping
	label.preferredMaxLayoutWidth = gui.fontSize * 60; // pd gui wraps at 60 chars
	[label sizeToFit];
	
	// create frame based on computed label size
	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		CGRectGetWidth(label.frame),
		CGRectGetHeight(label.frame));
	
	Comment *c = [[Comment alloc] initWithFrame:frame];

	c.label = label;
	[c addSubview:c.label];
	
	return c;
}

#pragma mark Overridden Getters & Setters

- (NSString*)type {
	return @"Comment";
}

@end
