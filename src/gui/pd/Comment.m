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

+ (id)commentFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 4) { // sanity check
		DDLogWarn(@"Comment: cannot create, atom line length < 4");
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

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.label.numberOfLines = 0;
		self.label.lineBreakMode = NSLineBreakByWordWrapping;
	}
    return self;
}

- (void)reshapeForGui:(Gui *)gui {

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize * gui.scaleX];
	CGSize charSize = [@"0" sizeWithFont:self.label.font]; // assumes monspaced font
	self.label.preferredMaxLayoutWidth = charSize.width * (GUI_LINE_WRAP - 1);
	[self.label sizeToFit];
	if(self.label.text.length > GUI_LINE_WRAP) { // force line wrapping based on size
		CGRect labelFrame = self.label.frame;
		labelFrame.size.width = self.label.preferredMaxLayoutWidth;
		labelFrame.size.height = self.label.font.lineHeight * ((self.label.text.length / GUI_LINE_WRAP) + 1);
		self.label.frame = labelFrame;
	}

	// bounds based on computed label size
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Comment";
}

@end
