/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * This class is largely adapted from the LastFM app:
 * https://github.com/c99koder/lastfm-iphone/blob/master/Classes/UIViewController%2BNowPlayingButton.h
 *
 */
#import "NowPlayingTableViewController.h"

#import "AppDelegate.h"
#import "Util.h"

// help from http://stackoverflow.com/questions/2071028/want-to-add-uinavigationbar-rightbarbutton-like-now-playing-button-of-ipod-wh
@implementation NowPlayingTableViewController

- (void)viewWillAppear:(BOOL)animated {

	// don't need button on iPad since patch view is always shown
	if(![Util isDeviceATablet]) {
		AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
		if(app.sceneManager.scene) {
			self.showNowPlayingButton = YES;
		}
		else {
			self.showNowPlayingButton = NO;
		}
	}
	
	[super viewWillAppear:animated];
}

- (void)setShowNowPlayingButton:(BOOL)show {
	_showNowPlayingButton = show;
	if(show) {
		if(!self.navigationItem.rightBarButtonItem) {
			self.navigationItem.rightBarButtonItem =
				[[UIBarButtonItem alloc] initWithTitle:@"Now Playing"
												 style:UIBarButtonItemStylePlain
												target:self
												action:@selector(nowPlayingPressed:)];
		}
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)nowPlayingPressed:(id)sender {

	// this should always be set on iPad since it's the detail view,
	// so this code should only be called on iPhone
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if(!app.patchViewController) {
		
		// create a new patch view and push it on the stack
		UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
		PatchViewController *patchView = [board instantiateViewControllerWithIdentifier:@"PatchViewController"];
		if(!patchView) {
			DDLogError(@"NowPlayingTableViewController: couldn't create patch view");
			return;
		}
		[self.navigationController pushViewController:patchView animated:YES];
	}
}

@end
