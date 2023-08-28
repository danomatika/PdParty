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
#import "AppDelegate.h"

@implementation ConsoleViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set size in iPad popup
//	if(Util.isDeviceATablet) {
//		self.preferredContentSize = CGSizeMake(320.0, 600.0);
//	}
	
	// do not extend under nav bar
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
	self.textView.scrollEnabled = YES;
	self.textView.showsVerticalScrollIndicator = YES;
	self.textView.editable = NO;
	self.textView.bounces = NO;
	self.textView.font = [UIFont fontWithName:GUI_FONT_NAME size:12];
	self.textView.minimumZoomScale = self.textView.maximumZoomScale; // no zooming
	self.textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
	
	[self.view addSubview:self.textView];
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
	                                                                  options:0
	                                                                  metrics:nil
	                                                                    views:@{@"view" : self.textView}]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
	                                                                  options:0
	                                                                  metrics:nil
	                                                                    views:@{@"view" : self.textView}]];

	self.navigationItem.title = @"Console";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];

	// opaque nav bar if content is scrollable
	if(@available(iOS 13.0, *)) {
		self.navigationController.navigationBar.scrollEdgeAppearance =
			self.navigationController.navigationBar.standardAppearance;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	Log.textViewLogger.textView = self.textView;
	[super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	Log.textViewLogger.textView = nil;
}

// update the scenemanager if there are rotations while the PatchView is hidden
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
		app.sceneManager.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
	}];
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

// lock to orientations allowed by the current scene
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	if(app.sceneManager.scene && !app.sceneManager.isRotated) {
		return app.sceneManager.scene.preferredOrientations;
	}
	return UIInterfaceOrientationMaskAll;
}

#pragma mark UI

- (void)donePressed:(id)sender {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
