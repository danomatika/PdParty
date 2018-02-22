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

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 4) { // sanity check
		DDLogWarn(@"Comment: cannot create, atom line length < 4");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.numForcedLineBreaks = 0;
		self.label.numberOfLines = 0;
		self.label.lineBreakMode = NSLineBreakByWordWrapping;
		self.userInteractionEnabled = NO; // not interactive, so don't accept touch events

		self.originalFrame = CGRectMake(
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
				self.numForcedLineBreaks++;
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
		// remove and stray backslashes
		[text replaceOccurrencesOfString:@"\\"
							   withString:@""
								  options:NSCaseInsensitiveSearch
									range:NSMakeRange(0, text.length)];
		self.label.text = text;
	}
	return self;
}

- (void)reshape {

	// label
	self.label.font = [UIFont fontWithName:self.gui.fontName size:(self.gui.fontSize * self.gui.scaleFont)];
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.label.font}]; // assumes monspaced font
	charSize.width = ceilf(charSize.width);
	charSize.height = ceilf(charSize.height);
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
	CGRect labelFrame = [self.label.text boundingRectWithSize:maxLabelSize
													  options:NSStringDrawingUsesLineFragmentOrigin
												   attributes:@{NSFontAttributeName:self.label.font}
													  context:nil];
	labelFrame.size.width = ceilf(labelFrame.size.width);
	labelFrame.size.height = ceilf(labelFrame.size.height);
	self.label.frame = labelFrame;

	// bounds based on computed label size
	self.frame = CGRectMake(
		roundf(self.originalFrame.origin.x * self.gui.scaleX + self.gui.offsetX),
		roundf(self.originalFrame.origin.y * self.gui.scaleY + self.gui.offsetY),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

// overridden so $0 or #0 is not replaced in label text
- (void)replaceDollarZerosForGui:(Gui *)gui fromPatch:(PdFile *)patch {
	self.sendName = [gui replaceDollarZeroStringsIn:self.sendName fromPatch:patch];
	self.receiveName = [gui replaceDollarZeroStringsIn:self.receiveName fromPatch:patch];
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Comment";
}

@end
