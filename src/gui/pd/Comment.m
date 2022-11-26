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

@interface Comment () {
	int lineWrap; ///< max char width before wrapping to next line
}
@end

@implementation Comment

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 4) { // sanity check
		DDLogWarn(@"Comment: cannot create, atom line length < 4");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		lineWrap = GUI_LINE_WRAP;
		self.numForcedLineBreaks = 0;
		self.label.numberOfLines = 0;
		self.label.lineBreakMode = NSLineBreakByWordWrapping;
		self.userInteractionEnabled = NO; // not interactive, so don't accept touch events

		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			0, 0); // size based on label size

		// create the comment string, handle options at end
		NSMutableString *text = [NSMutableString string];
		BOOL appendSpace = NO;
		BOOL optionsFound = NO;
		for(int i = 4; i < (int)line.count; i++) {
			if([line[i] isKindOfClass:NSNull.class]) {
				optionsFound = YES;
				i++;
				if(i == line.count) {break;}
			}
			if(optionsFound) { // options
				if([line[i] isEqualToString:@"f"]) {
					// manual width
					i++;
					if(i == line.count) {break;}
					lineWrap = [line[i] intValue];
				}
			}
			else { // space-separated text
				if([line[i] isEqualToString:@";"]) {
					// semi ; force a line break in pd gui
					[text appendString:@";\n"];
					self.numForcedLineBreaks++;
					appendSpace = NO;
				}
				else {
					if(appendSpace) {
						[text appendString:@" "];
					}
					appendSpace = YES;
					[text appendString:line[i]];
				}
			}
		}
		self.label.text = text;
	}
	return self;
}

- (void)reshape {

	// label
	self.label.font = [UIFont fontWithName:self.gui.fontName size:self.gui.fontSize * self.gui.scaleHeight];
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.label.font}]; // assumes monspaced font
	charSize.width = ceil(charSize.width);
	charSize.height = ceil(charSize.height);
	self.label.preferredMaxLayoutWidth = charSize.width * (lineWrap - 1);
	CGSize maxLabelSize;
	maxLabelSize.width = charSize.width * lineWrap;
	if(self.label.text.length > lineWrap) { // force line wrapping based on size
		maxLabelSize.height = charSize.height * ((self.label.text.length / lineWrap + 1));
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
	labelFrame.size.width = ceil(labelFrame.size.width);
	labelFrame.size.height = ceil(labelFrame.size.height);
	self.label.frame = labelFrame;

	// bounds based on computed label size
	self.frame = CGRectMake(
		round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
		round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
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
