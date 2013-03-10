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
#import "IEMWidget.h"

#import "Gui.h"

@implementation IEMWidget

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];

	// label
	[self reshapeLabelForGui:gui];
}

- (void)reshapeLabelForGui:(Gui *)gui {
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize * gui.scaleX];
	[self.label sizeToFit];
	self.label.frame = CGRectMake(
		0, -CGRectGetHeight(self.label.frame),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (NSString*)type {
	return @"IEMWidget";
}

#pragma mark WidgetListener


@end
