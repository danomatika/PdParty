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

#import "Log.h"
#import "Util.h"
#import "AppDelegate.h"
#import "Popover.h"

@interface PatchViewController () {
	NSMutableDictionary *activeTouches; //< for persistent ids
	KeyGrabberView *grabber; //< for keyboard events
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) Popover *controlsPopover;

/// check the current orientation against the scene's prefferred orientations &
/// manually rotate the view if needed
- (void)checkOrientation;

/// display the controls on screen or in a popup as required by the current scene
- (void)updateControls;

/// close the controls popover
- (void)dismissControlsPopover;

/// add/remove default background
- (void)addBackground;
- (void)removeBackground;

@end

@implementation PatchViewController

- (void)awakeFromNib {

	// set here for when patch is pushed onto the nav controller manually by the
	// Now Playing button
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	self.sceneManager = app.sceneManager;

	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// do not extend under nav bar on iOS 7
	if([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}

	_rotation = 0;
	activeTouches = [[NSMutableDictionary alloc] init];
	
	// set instance pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.patchViewController = self;
	
	// set up controls view
	self.controlsView = [[ControlsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), [ControlsView baseHeight])];
	self.controlsView.sceneManager = app.sceneManager;
	
	// set up menu buttons
	self.menuViewController = [[MenuViewController alloc] init];

	// start keygrabber
	grabber = [[KeyGrabberView alloc] init];
	grabber.active = YES;
	grabber.delegate = self;
	[self.view addSubview:grabber];
	
	// set title here since view hasn't been inited when opening on iPhone
	if(![Util isDeviceATablet]) {
		self.navigationItem.title = self.sceneManager.scene.name;
	}
}

- (void)dealloc {
	
	// clear pointer when the view is popped
	[self.sceneManager updateParent:nil];
	
	// clear instance pointer for Now Playing button on iPhone
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.patchViewController = nil;
}

// called when view bounds change (after rotations, etc)
- (void)viewDidLayoutSubviews {
	
	// update background, if set
	if(self.background) {
		self.background.frame = self.view.bounds;
	}
	
	// update parent, orient, and reshape scene
	[self.sceneManager updateParent:self.view];
	[self checkOrientation];
	[self.sceneManager reshapeToParentSize:self.view.bounds.size];

	// update on screen controls
	[self updateControls];
	self.navigationItem.title = self.sceneManager.scene.name;

	// needed for autolayout
	[self.view layoutSubviews];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.sceneManager.currentOrientation = [self interfaceOrientation];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

// lock orientation based on scene's preferred orientation mask
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if(self.sceneManager.scene) {
		return self.sceneManager.scene.preferredOrientations;
	}
	return UIInterfaceOrientationMaskAll;
}

- (void)viewWillAppear:(BOOL)animated {
	if(self.sceneManager.scene) {
		if(self.background) {
			[self removeBackground];
		}
	}
	else if(!self.background) {
		[self addBackground];
	}
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// clean up popover or there will be an exception when navigating away while
	// popover is still displayed on iPhone
	[self dismissControlsPopover];
}
#pragma mark Scene Management

- (void)openScene:(NSString *)path withType:(NSString *)type {

	// set the scenemanager here since iPhone dosen't load view until *after* this is called
	if(!self.sceneManager) {
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		self.sceneManager = app.sceneManager;
	}
	
	if([self.sceneManager openScene:path withType:type forParent:self.view]) {
		
		// does the scene need key events?
		grabber.active = self.sceneManager.scene.requiresKeys;
		DDLogVerbose(@"PatchViewController: %@ key grabber", grabber.active ? @"enabled" : @"disabled");
	
		// set nav controller title
		self.navigationItem.title = self.sceneManager.scene.name;
		
		// make sure controls are updated and nav bar buttons are created
		[self updateControls];
		
		// don't need background anymore
		if(self.background) {
			[self removeBackground];
		}
	}
	
	// hide iPad browser popover on selection 
	if(self.masterPopoverController != nil) {
		[self.masterPopoverController dismissPopoverAnimated:YES];
	}
	[self dismissControlsPopover]; // controls popover too
}

- (void)closeScene {
	[self.sceneManager closeScene];
}

#pragma mark UI

- (void)controlsNavButtonPressed:(id)sender {
	if(!self.controlsPopover.popoverVisible) {
		[self.controlsPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
									 permittedArrowDirections:UIPopoverArrowDirectionUp
													 animated:YES];
	}
	else {
		[self.controlsPopover dismissPopoverAnimated:YES];
	}
}

- (void)infoNavButtonPressed:(id)sender {
	// cause transition to info view
	[self performSegueWithIdentifier:@"showInfo" sender:self];
}

#pragma mark Overridden Getters / Setters

- (void)setRotation:(int)rotation {
	if(rotation == _rotation) {
		return;
	}
	_rotation = rotation;
	if(self.rotation == 0) {
		if(!CGAffineTransformIsIdentity(self.view.transform)) {
			DDLogVerbose(@"PatchViewController: rotating view back to 0");
			self.view.transform = CGAffineTransformIdentity;
			self.view.bounds = CGRectMake(0, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds));
		}
	}
	else {
		if(CGAffineTransformIsIdentity(self.view.transform)) {
			self.view.transform = CGAffineTransformMakeRotation(self.rotation / 180.0 * M_PI);
			self.view.bounds = CGRectMake(0, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds));
		}
	}
}

#pragma mark Touches

// persistent touch ids from ofxIPhone:
// https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiPhone/src/core/ofxiOSEAGLView.mm
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	
	for(UITouch *touch in touches) {
		int touchId = 0;
		while([[activeTouches allValues] containsObject:[NSNumber numberWithInt:touchId]]) {
			touchId++;
		}
		[activeTouches setObject:[NSNumber numberWithInt:touchId]
						  forKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			//DDLogVerbose(@"touch %d: down %.4f %.4f", touchId+1, pos.x, pos.y);
			[self.sceneManager sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			//DDLogVerbose(@"touch %d: moved %d %d", touchId+1, (int) pos.x, (int) pos.y);
			[self.sceneManager sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		[activeTouches removeObjectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			//DDLogVerbose(@"touch %d: up %d %d", touchId+1, (int) pos.x, (int) pos.y);
			[self.sceneManager sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

#pragma mark KeyGrabberDelegate

- (void)keyPressed:(int)key {
	[self.sceneManager sendKey:key];
}

#pragma mark UISplitViewControllerDelegate

// iOS 6 & 7
- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {

	if([Util isDeviceATablet]) {
		barButtonItem.title = nil;
		barButtonItem.image = [UIImage imageNamed:@"browser"];
		if(!barButtonItem.image) { // fallback
			barButtonItem.title = @"Patches";
		}
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

// hide controls popover when browser is shown on iPad
- (void)splitViewController:(UISplitViewController *)splitController popoverController:(UIPopoverController *)popoverController willPresentViewController:(UIViewController *)viewController {
	[self dismissControlsPopover];
}

#pragma mark Private

- (void)checkOrientation {

	// rotates toward home button on bottom or left
	int currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	if((self.sceneManager.scene.preferredOrientations == UIInterfaceOrientationMaskAll) ||
	   (self.sceneManager.scene.preferredOrientations == UIInterfaceOrientationMaskAllButUpsideDown)) {
		self.rotation = 0;
	}
	else if(UIInterfaceOrientationIsLandscape(currentOrientation)) {
		if(self.sceneManager.scene.preferredOrientations & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown)) {
			DDLogVerbose(@"PatchViewController: rotating view to portrait for current scene");
			if(currentOrientation == UIInterfaceOrientationLandscapeLeft) {
				self.rotation = 90;
				self.sceneManager.currentOrientation = UIInterfaceOrientationLandscapeLeft;
			}
			else {
				self.rotation = -90;
				self.sceneManager.currentOrientation = UIInterfaceOrientationLandscapeRight;
			}
		}
		else {
			self.rotation = 0;
		}
	}
	else { // default is portrait
		if(self.sceneManager.scene.preferredOrientations & UIInterfaceOrientationMaskLandscape) {
			DDLogVerbose(@"PatchViewController: rotating view to landscape for current scene");
			if(currentOrientation == UIInterfaceOrientationPortrait) {
				self.rotation = -90;
				self.sceneManager.currentOrientation = UIInterfaceOrientationPortrait;
			}
			else {
				self.rotation = 90;
				self.sceneManager.currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
			}
		}
		else {
			self.rotation = 0;
		}
	}
}

- (void)updateControls {

	if(self.sceneManager.scene.requiresOnscreenControls) {
	
		// controls should be on screen at the bottom of the view
		if(self.controlsPopover || !self.controlsView.superview) {
			[self.controlsView removeFromSuperview];
			
			// make sure to close popover if it's still visible on iPad
			[self dismissControlsPopover];
			self.controlsPopover = nil;
			
			// make sure the color is black as it might have been white in a popover
			if([Util deviceOSVersion] >= 7.0) {
				self.controlsView.lightBackground = NO;
			}
			
			// create nav button if the scene has any info to show
			if(self.sceneManager.scene.hasInfo) {
				self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil
																						  style:UIBarButtonItemStylePlain
																						 target:self
																						action:@selector(infoNavButtonPressed:)];
				if([Util deviceOSVersion] >= 7.0) {
					self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"info"];
				}
				else { // light button on iOS 6
					self.navigationItem.rightBarButtonItem.image = [Util image:[UIImage imageNamed:@"info"] withTint:[UIColor whiteColor]];
				}
				if(!self.navigationItem.rightBarButtonItem.image) { // fallback
					self.navigationItem.rightBarButtonItem.title = @"Info";
				}
			}
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
			
			// larger sizing for iPad
			if([Util isDeviceATablet]) {
				[self.controlsView defaultSize];
			}
			
			// add to this view
			[self.view addSubview:self.controlsView];
	
			// auto layout constraints
			[self.controlsView alignToSuperviewBottom];
		}
		self.controlsView.height = CGRectGetHeight(self.view.bounds) - self.sceneManager.scene.contentHeight;
	}
	else {
	
		// controls should be in a popup activated from a nav button
		if(!self.controlsPopover && self.sceneManager.scene) {
			[self.controlsView removeFromSuperview];
			
			// white background for pop over on iOS 7, otherwise black
			if([Util deviceOSVersion] >= 7.0) {
				self.controlsView.lightBackground = YES;
			}
			
			// create nav button
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil
																					  style:UIBarButtonItemStylePlain
																					 target:self
																					 action:@selector(controlsNavButtonPressed:)];
			if([Util deviceOSVersion] >= 7.0) {
				self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"controls"];
			}
			else { // light button on iOS 6
				self.navigationItem.rightBarButtonItem.image = [Util image:[UIImage imageNamed:@"controls"] withTint:[UIColor whiteColor]];
			}
			
			if(!self.navigationItem.rightBarButtonItem.image) { // fallback
				self.navigationItem.rightBarButtonItem.title = @"Controls";
			}
			self.navigationItem.rightBarButtonItem.enabled = YES;
			
			// smaller controls in iPad popover
			if([Util isDeviceATablet]) {
				[self.controlsView halfSize];
			}
				
			// create popover with controls & menu
			int width = [ControlsView baseWidth];
			UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, self.controlsView.height + self.menuViewController.height)];
			view.autoresizesSubviews = YES;
			view.translatesAutoresizingMaskIntoConstraints = NO;
			[view addSubview:self.controlsView];
			[view addSubview:self.menuViewController.view];
			self.controlsPopover = [[Popover alloc] initWithContentView:view andSourceController:self];
			self.controlsPopover.backgroundColor = self.controlsView.backgroundColor;
			
			self.menuViewController.popover = self.controlsPopover;
			self.menuViewController.view.backgroundColor = self.controlsView.backgroundColor;
			self.menuViewController.view.frame = CGRectMake(0, self.controlsView.height, width, self.menuViewController.height);
			
			[self.controlsView alignToSuperviewTop];
			[self.menuViewController alignToSuperviewBottom];
			[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : view}]];
			[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
																				options:0
																				metrics:nil
																				  views:@{@"view" : view}]];
		}
	}
	[self.controlsView setNeedsUpdateConstraints];
	[self.controlsView.superview setNeedsUpdateConstraints];
	
	[self.controlsView updateControls];
}

- (void)dismissControlsPopover {
	if(self.controlsPopover.popoverVisible) {
		[self.controlsPopover dismissPopoverAnimated:YES];
	}
}

- (void)addBackground {
	self.background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"patchview_bg"]];
	self.background.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:self.background];
}

- (void)removeBackground {
	[self.background removeFromSuperview];
	self.background = nil;
}

@end
