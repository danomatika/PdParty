/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * References:
 *   http://pinkstone.co.uk/how-to-create-popovers-in-ios-9/
 *   http://stackoverflow.com/questions/25319179/uipopoverpresentationcontroller-on-ios-8-iphone
 *
 */
#import "Popover.h"

#import "Util.h"

@interface Popover () <UIPopoverPresentationControllerDelegate> {
	UIViewController *popover;
}
@property (readwrite, nonatomic) UIViewController *sourceController;
@property (readwrite, nonatomic) UIView *contentView;
@end

@implementation Popover

- (id)initWithContentView:(UIView *)contentView andSourceController:(UIViewController *)sourceController {
	self = [super init];
	if(self) {
		self.sourceController = sourceController;
		self.contentView = contentView;
		self.contentSize = contentView.frame.size;
		self.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame));
		[self.view addSubview:self.contentView];
	}
	return self;
}

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated {
	self.preferredContentSize = self.contentSize;
	self.modalPresentationStyle = UIModalPresentationPopover;

	UIPopoverPresentationController *ppc = [self popoverPresentationController];
	ppc.permittedArrowDirections = arrowDirections;
	ppc.sourceRect = rect;
	ppc.sourceView = view;
	if(self.backgroundColor) {
		ppc.backgroundColor = self.backgroundColor;
	}
	ppc.delegate = self;

	[self.sourceController presentViewController:self animated:animated completion:nil];
	popover = self;
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated {
	self.view.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
	self.preferredContentSize = self.contentSize;
	self.modalPresentationStyle = UIModalPresentationPopover;

	UIPopoverPresentationController *ppc = [self popoverPresentationController];
	ppc.permittedArrowDirections = arrowDirections;
	ppc.barButtonItem = item;
	if(self.backgroundColor) {
		ppc.backgroundColor = self.backgroundColor;
	}
	ppc.delegate = self;

	[self.sourceController presentViewController:self animated:animated completion:nil];
	popover = self;
}

- (void)dismissPopoverAnimated:(BOOL)animated {
	[self dismissViewControllerAnimated:animated completion:nil];
	popover = nil;
}

- (BOOL)popoverVisible {
	return (popover ? YES : NO);
}

#pragma mark UIPopoverPresentationControllerDelegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
	popover = nil; // catch dismissal or popoverVisible will be wrong later on
}

#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
	return UIModalPresentationNone; // specify this particular value in order to make it work on iPhone
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
	// this method is called in iOS 8.3 or later regardless of trait collection, in which case use the original presentation style (UIModalPresentationNone signals no adaptation)
	return UIModalPresentationNone;
}

@end
