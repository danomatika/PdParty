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
#import "PatchViewController.h"

#import "Gui.h"
#import "PdParser.h"
#import "PdFile.h"
#import "Log.h"

@interface PatchViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (assign) BOOL haveReshaped;
@end

@implementation PatchViewController

- (id)init {
	self = [super init];
    if(self) {
		self.haveReshaped = NO;
	}
	return self;
}

- (void)viewDidLayoutSubviews {
	
	self.gui.bounds = self.view.bounds;
	
	// do animations if gui has already been setup once
	// http://www.techotopia.com/index.php/Basic_iOS_4_iPhone_Animation_using_Core_Animation
	if(self.haveReshaped) {
		[UIView beginAnimations:nil context:nil];
	}
	[self.gui reshapeWidgets];
	if(self.haveReshaped) {
		[UIView commitAnimations];
	}
	else {
		self.haveReshaped = YES;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Managing the Current Patch

- (void)setCurrentPatch:(NSString*)newPatch {
    
	if(_currentPatch != newPatch) {
        _currentPatch = newPatch;
		
		// create gui here as iPhone dosen't load view until *after* this is called
		if(!self.gui) {
			self.gui = [[Gui alloc] init];
		}
		
		// close open patch
		if(self.gui.currentPatch) {
			[self.gui.currentPatch closeFile];
			for(Widget *widget in self.gui.widgets) {
				[widget removeFromSuperview];
			}
			[self.gui.widgets removeAllObjects];
			self.gui.currentPatch = nil;
		}
		
		// open new patch
		if(self.currentPatch) {
			
			NSString *fileName = [self.currentPatch lastPathComponent];
			NSString *dirPath = [self.currentPatch stringByDeletingLastPathComponent];
			
			DDLogVerbose(@"Opening %@ %@", fileName, dirPath);
			self.navigationItem.title = [fileName stringByDeletingPathExtension]; // set view title
			
			// load gui
			[self.gui addWidgetsFromPatch:self.currentPatch];
			self.gui.currentPatch = [PdFile openFileNamed:fileName path:dirPath];
			DDLogVerbose(@"Adding %d widgets", self.gui.widgets.count);
			for(Widget *widget in self.gui.widgets) {
				[self.view addSubview:widget];
			}
			self.haveReshaped = NO;
		}
    }

    if(self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {

	if([Util isDeviceATablet]) {
		barButtonItem.title = NSLocalizedString(@"Patches", @"Patches");
	}
    
	[self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

// hide master view controller by default on all orientations
- (BOOL)splitViewController:(UISplitViewController *)splitController shouldHideViewController:(UIViewController *)viewController inOrientation:(UIInterfaceOrientation)orientation {
	return YES;
}

@end
