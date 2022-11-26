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
#import "MenuViewController.h"

#import "AppDelegate.h"
#import "Menubang.h"
#import "Log.h"
#import "Util.h"
#import "Popover.h"
#import "ConsoleViewController.h"
#import "PatchViewController.h"

#define CELL_SIZE 60
#define PADDING   10

@interface MenuViewController () {
	BOOL scrolls; ///< YES if there are enough buttons for the menu to scroll
	NSMapTable *menubangButtons; ///< menubangs via button id keys
	int consoleButtonIndex;
	int speakerButtonIndex;
	int infoButtonIndex;
}
@end

@implementation MenuViewController

- (id)init {
	self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
	if(self) {
		menubangButtons = [[NSMapTable alloc] init];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// make sure the cell class is known
	[self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"MenuCell"];
	
	self.collectionView.allowsSelection = NO;
	self.collectionView.showsHorizontalScrollIndicator = NO;
	
	UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	layout.itemSize = CGSizeMake(CELL_SIZE, CELL_SIZE);
	layout.minimumInteritemSpacing = PADDING;
	layout.minimumLineSpacing = PADDING;
	layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	
	// light popups
	self.lightBackground = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.collectionView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[menubangButtons removeAllObjects];
	consoleButtonIndex = -1;
	speakerButtonIndex = -1;
	infoButtonIndex = -1;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma Layout

- (void)alignToSuperview {
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
}

- (void)alignToSuperviewBottom {
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
}

- (void)alignToSuperviewTop {
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
	[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]"
																				options:0
																				metrics:nil
																				  views:@{@"view" : self.view}]];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// restart button is always index 0
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	int index = 1; // restart button + 1
	int num = self.numDefaultButtons + [Menubang menubangCount];
	if(Util.isDeviceAPhone) {
		speakerButtonIndex = index;
		index++;
	}
	if(Log.textViewLoggerEnabled) {
		consoleButtonIndex = index;
		index++;
	}
	if(app.sceneManager.scene.hasInfo) {
		infoButtonIndex = index;
	}
	return num;;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"MenuCell" forIndexPath:indexPath];
	
	for(UIView *view in cell.contentView.subviews) {
		[view removeFromSuperview];
	}
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = cell.bounds;
	button.translatesAutoresizingMaskIntoConstraints = YES;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	button.titleLabel.textAlignment = NSTextAlignmentCenter;
	button.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	button.titleLabel.adjustsFontSizeToFitWidth = YES;
	button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	button.titleLabel.font = [UIFont systemFontOfSize:14];
	
	UIColor *normalColor;
	UIColor *selectedColor;
	
	// add background when scrolling so you can see there are more buttons off the edge
	if(scrolls) {
		button.layer.masksToBounds = YES;
		button.layer.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
		button.layer.cornerRadius = 5;
		normalColor = self.view.tintColor;
		selectedColor = UIColor.lightGrayColor;
	}
	else {
		normalColor = self.view.tintColor;
		selectedColor = self.lightBackground ? UIColor.lightTextColor : UIColor.darkGrayColor;
	}
	
	[button setTitleColor:normalColor forState:UIControlStateNormal];
	[button setTitleColor:selectedColor forState:UIControlStateSelected];
	
	button.showsTouchWhenHighlighted = YES;
	
	switch(indexPath.row) {
		case 0:
			//[button setTitle:@"Restart Scene" forState:UIControlStateNormal];
			[button setImage:[Util image:[UIImage imageNamed:@"reload"] withTint:normalColor]  forState:UIControlStateNormal];
			[button setImage:[Util image:[UIImage imageNamed:@"reload"] withTint:selectedColor] forState:UIControlStateSelected];
			[button addTarget:self action:@selector(restartPressed:) forControlEvents:UIControlEventTouchUpInside];
			break;
		default:
			if(indexPath.row == speakerButtonIndex) {
				//[button setTitle:@"Speaker" forState:UIControlStateNormal];
				AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
				[button setImage:[Util image:[UIImage imageNamed:@"speaker"] withTint:normalColor]  forState:UIControlStateNormal];
				[button setImage:[Util image:[UIImage imageNamed:@"speaker"] withTint:selectedColor] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(speakerPressed:) forControlEvents:UIControlEventTouchUpInside];
				button.selected = app.pureData.earpieceSpeaker;
			}
			else if(indexPath.row == consoleButtonIndex) {
				//[button setTitle:@"Show Console" forState:UIControlStateNormal];
				[button setImage:[Util image:[UIImage imageNamed:@"console"] withTint:normalColor]  forState:UIControlStateNormal];
				[button setImage:[Util image:[UIImage imageNamed:@"console"] withTint:selectedColor] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(showConsolePressed:) forControlEvents:UIControlEventTouchUpInside];
			}
			else if(indexPath.row == infoButtonIndex) {
				//[button setTitle:@"Show Info" forState:UIControlStateNormal];
				[button setImage:[Util image:[UIImage imageNamed:@"info-big"] withTint:normalColor]  forState:UIControlStateNormal];
				[button setImage:[Util image:[UIImage imageNamed:@"info-big"] withTint:selectedColor] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(showInfoPressed:) forControlEvents:UIControlEventTouchUpInside];
			}
			else {
				NSInteger row = indexPath.row - self.numDefaultButtons;
				Menubang *m = [[Menubang menubangs] objectAtIndex:row];
				[menubangButtons setObject:m forKey:button]; // store button used for menubang
				if(m.imagePath) {
					UIImage *image = [UIImage imageWithContentsOfFile:m.imagePath];
					if(image) {
						[button setImage:[Util image:image withTint:normalColor]  forState:UIControlStateNormal];
						[button setImage:[Util image:image withTint:selectedColor] forState:UIControlStateSelected];
						[button addTarget:self action:@selector(menubangPressed:) forControlEvents:UIControlEventTouchUpInside];
						break;
					}
				}
				[button setTitle:[m.name stringByReplacingOccurrencesOfString:@"_" withString:@" "] forState:UIControlStateNormal];
				[button addTarget:self action:@selector(menubangPressed:) forControlEvents:UIControlEventTouchUpInside];
			}
			break;
	}
	[cell.contentView addSubview:button];

	return cell;
}

#pragma mark UICollectionViewLayoutDelegate

// use insets to center cells if total width is smaller than frame width
// https://wingoodharry.wordpress.com/2015/05/05/centre-uicollectionview-cells-horizontally-ios
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	NSInteger numCells = [self.collectionView numberOfItemsInSection:section];
	NSInteger contentWidth = (CELL_SIZE * numCells) + (PADDING * (numCells-1));
	NSInteger inset = (self.view.frame.size.width - contentWidth) / 2;
	 if(contentWidth < self.view.frame.size.width) {
		scrolls = NO;
		return UIEdgeInsetsMake(0, inset, 0, inset);
	}
	scrolls = YES;
	return UIEdgeInsetsMake(0, PADDING, 0, PADDING); // top left bottom right
}

#pragma mark UI

- (void)restartPressed:(id)sender {
	DDLogVerbose(@"Menu: restart button pressed");
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	[self.popover dismissPopoverAnimated:YES];
	if(![app.sceneManager reloadScene]) {
		// didn't open so bail out
		if(!Util.isDeviceATablet) {
			[app.patchViewController.navigationController popViewControllerAnimated:YES];
		}
	}
}

- (void)speakerPressed:(id)sender {
	DDLogVerbose(@"Menu: speaker button pressed");
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.pureData.earpieceSpeaker = !app.pureData.earpieceSpeaker;
	[(UIButton *)sender setSelected:app.pureData.earpieceSpeaker];
}

- (void)showConsolePressed:(id)sender {
	DDLogVerbose(@"Menu: show console button pressed");
	[self.popover dismissPopoverAnimated:YES];
	ConsoleViewController *consoleView = [[ConsoleViewController alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:consoleView];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	navigationController.modalInPopover = YES;
	[self.popover.sourceController.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void)showInfoPressed:(id)sender {
	DDLogVerbose(@"Menu: show info button pressed");
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	[self.popover dismissPopoverAnimated:YES];
	[app.patchViewController performSegueWithIdentifier:@"showInfo" sender:self];
}

- (void)menubangPressed:(id)sender {
	Menubang *m = [menubangButtons objectForKey:sender];
	if(!m) {
		DDLogWarn(@"Menu: menubang button pressed, but menubang not found %@", sender);
		return;
	}
	DDLogVerbose(@"Menu: menubang %@ button pressed", m.name);
	[m sendBang];
	[self.popover dismissPopoverAnimated:YES];
}

#pragma mark Overridden Getters/Setters

- (int)cellSize {
	return CELL_SIZE;
}

- (int)height {
	return CELL_SIZE + PADDING*2;
}

- (void)setLightBackground:(BOOL)lightBackground {
	if(_lightBackground == lightBackground) {
		return;
	}
	_lightBackground = lightBackground;
	if(lightBackground) {
		self.collectionView.backgroundColor = UIColor.whiteColor;
		
	}
	else {
		self.collectionView.backgroundColor = UIColor.blackColor;
	}
}

- (UIColor *)backgroundColor {
	return self.collectionView.backgroundColor;
}

- (int)numDefaultButtons {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	int num = 1; // restart
	if(Util.isDeviceAPhone) { // speaker
		num++;
	}
	if(Log.textViewLoggerEnabled) { // console
		num++;
	}
	if(app.sceneManager.scene.hasInfo) { // info
		num++;
	}
	return num;
}

@end
