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
#import "InfoViewController.h"

#import "AppDelegate.h"

@interface InfoViewController () {
	int defaultCellHeight;
	SceneManager *sceneManager;
}
@end

@implementation InfoViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	// this should probably calculated using the default height of a cell, but that seems to return 0 ...
	defaultCellHeight = 44; // reasonable default judging from values in the storyboard
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	sceneManager = app.sceneManager;
	
	self.nameLabel.text = sceneManager.scene.name;
	self.artistLabel.text = sceneManager.scene.artist;
	self.categoryLabel.text = sceneManager.scene.category;
	self.descriptionTextView.text = sceneManager.scene.description;
	if([Util isDeviceAPhone]) {
		self.earpieceSwitch.enabled = YES;
		self.earpieceSwitch.on = app.pureData.earpieceSpeaker;
	}
	else {
		self.earpieceSwitch.enabled = NO;
		self.earpieceSwitch.on = NO;
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
}

// update the scenemanager if there are rotations while the PatchView is hidden
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self->sceneManager.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
	}];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

// lock to orientations allowed by the current scene
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if(sceneManager.scene && !sceneManager.isRotated) {
		return sceneManager.scene.preferredOrientations;
	}
	return UIInterfaceOrientationMaskAll;
}

#pragma mark UI

- (IBAction)earpieceChanged:(id)sender {
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.pureData.earpieceSpeaker = self.earpieceSwitch.on;
}

- (IBAction)restartScene:(id)sender {
	[sceneManager reloadScene];
}

- (void)donePressed:(id)sender {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDelegate

// make sure the text view cell expands to fill the empty space in the parent view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	if(indexPath.section == 1) { // description text view
		int numCells = ([Util isDeviceAPhone] ? 5 : 4);
		float size = CGRectGetHeight(self.view.bounds) - (defaultCellHeight * numCells) - 88; // 88 for space between groups
		return MAX(size, 2 * 22); // min size is 2 lines
	}
	return defaultCellHeight;
}

@end
