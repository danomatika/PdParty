/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "ConsoleViewController.h"

#import "Log.h"
#import "Util.h"
#import "Gui.h"
#import "TextViewLogger.h"

@implementation ConsoleViewController

- (void)viewDidLoad {
	self.view.backgroundColor = [UIColor whiteColor];
	
	// set size in iPad popup
	if([Util isDeviceATablet]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
	
	// do not extend under nav bar on iOS 7
	if([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
	self.textView.scrollEnabled = YES;
	self.textView.showsVerticalScrollIndicator = YES;
	self.textView.editable = NO;
	self.textView.bounces = NO;
	self.textView.font = [UIFont fontWithName:GUI_FONT_NAME size:12];
	self.textView.minimumZoomScale = self.textView.maximumZoomScale; // no zooming
	if([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
	
	[self.view addSubview:self.textView];
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.textView}]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.textView}]];

	self.navigationItem.title = @"Console";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
}

- (void)viewWillAppear:(BOOL)animated {
	[[Log textViewLogger] setTextView:self.textView];
	[super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[Log textViewLogger] setTextView:nil];
}

// lock orientation on iPhone
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if([Util isDeviceATablet]) {
		return UIInterfaceOrientationMaskAll;
	}
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark UI

- (void)donePressed:(id)sender {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end

