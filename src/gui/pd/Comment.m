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

	Comment *c = [[[self class] alloc] initWithFrame:CGRectZero];

	c.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on label size

	// create the comment string, handle escaped chars
	NSMutableString *text = [[NSMutableString alloc] init];
	BOOL appendSpace = NO;
	for(int i = 4; i < line.count; ++i) {
		if([[line objectAtIndex:i] isEqualToString:@"\\,"]) {
			[text appendString:@","];
		}
		else if([[line objectAtIndex:i] isEqualToString:@"\\;"]) {
			[text appendString:@";\n"]; // semi ; force a line break in pd gui
			c.numForcedLineBreaks++;
			appendSpace = NO;
		}
		else if([[line objectAtIndex:i] isEqualToString:@"\\$"]) {
			[text appendString:@"$"];
		}
		else {
			if(appendSpace) {
				[text appendString:@" "];
			}
			appendSpace = YES;
			[text appendString:[line objectAtIndex:i]];
		}
	}
	c.label.text = text;
	
//	DDLogVerbose(@"Comment: text is \"%@\"", text);
	
	return c;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.numForcedLineBreaks = 0;
		self.label.numberOfLines = 0;
		self.label.lineBreakMode = NSLineBreakByWordWrapping;
		self.userInteractionEnabled = NO; // not interactive, so don't accept touch events
	}
    return self;
}

- (void)reshapeForGui:(Gui *)gui {

	// label
	self.label.font = [UIFont fontWithName:gui.fontName size:gui.fontSize * gui.scaleX];
	CGSize charSize = [@"0" sizeWithFont:self.label.font]; // assumes monspaced font
	self.label.preferredMaxLayoutWidth = charSize.width * (GUI_LINE_WRAP - 1);
	CGSize maxLabelSize;
	maxLabelSize.width = charSize.width * (GUI_LINE_WRAP - 1);
	if(self.label.text.length > GUI_LINE_WRAP) { // force line wrapping based on size
		maxLabelSize.height = charSize.height * ((self.label.text.length / (GUI_LINE_WRAP - 1) + 1));
	}
	else {
		maxLabelSize.height = charSize.height;
	}
	if(self.numForcedLineBreaks > 0) {
		maxLabelSize.height += charSize.height * self.numForcedLineBreaks;
	}
	CGRect labelFrame = self.label.frame;
	labelFrame.size = [self.label.text sizeWithFont:self.label.font
								  constrainedToSize:maxLabelSize
									  lineBreakMode:self.label.lineBreakMode];
	self.label.frame = labelFrame;

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
