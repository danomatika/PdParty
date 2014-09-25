/*
 * Copyright (c) 2014 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */

#import "FileBrowserCell.h"

#import "Log.h"

@implementation FileBrowserCell

// override style since we always want the subtitle style
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if(self) {

		// add utility buttons
		NSMutableArray *rightUtilityButtons = [NSMutableArray new];
		
		// grey rename
		[rightUtilityButtons sw_addUtilityButtonWithColor:
		 [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
													title:@"Rename"];
								
		// red delete
		[rightUtilityButtons sw_addUtilityButtonWithColor:
		 [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
													title:@"Delete"];

		self.rightUtilityButtons = rightUtilityButtons;
	}
	return self;
}

@end
