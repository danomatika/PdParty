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
}

// update the scenemanager if there are rotations while the PatchView is hidden
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	sceneManager.currentOrientation = [self interfaceOrientation];
}

- (IBAction)restartScene:(id)sender {
	[sceneManager reloadScene];
}

#pragma mark UITableViewDelegate

// make sure the text view cell expands to fill the empty space in the parent view
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	if(indexPath.section == 1) {
		return CGRectGetHeight(self.view.bounds) - (defaultCellHeight * 4) - 88; // 88 for space between groups
	}
	return defaultCellHeight;
}

@end
