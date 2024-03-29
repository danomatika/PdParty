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

#import "PatchView.h"

//#define DEBUG_TOUCH

@interface PatchViewController () {
	NSMutableDictionary *activeTouches; ///< for persistent ids
	KeyGrabberView *keyGrabberView; ///< for keyboard events
}

@property (strong, nonatomic) Popover *controlsPopover;

/// check the current orientation against the scene's prefferred orientations &
/// manually rotate the view if needed
- (void)updateOrientation;

/// display the controls on screen or in a popup as required by the current scene
- (void)updateControls;

/// close the controls popover
- (void)dismissControlsPopover;

/// add default background
- (void)addBackground;

/// remove default background
- (void)removeBackground;

@end

@implementation PatchViewController

- (void)awakeFromNib {

	// make sure globals are set up as iPad will call this before AppDelegate
	// applicationDidFinishLaunching:
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	[app setup];

	// set here for when patch is pushed onto the nav controller manually by the
	// Now Playing button
	self.sceneManager = app.sceneManager;

	// make sure touches are forwarded
	[(PatchView *)self.view setTouchResponder:self];

	// clip anything outside of the current bounds, this is mostly applicable
	// to scenes which change the gui viewport
	self.view.clipsToBounds = YES;

	[super awakeFromNib];
}

- (void)dealloc {
	
	// clear pointer when the view is popped
	[self.sceneManager updateParent:nil];
	
	// clear instance pointer for Now Playing button on iPhone
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.patchViewController = nil;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// do not extend under nav bar
	self.edgesForExtendedLayout = UIRectEdgeNone;

	activeTouches = [NSMutableDictionary dictionary];
	
	// set instance pointer
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.patchViewController = self;
	
	// set up controls view
	CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), ControlsView.baseHeight);
	self.controlsView = [[SceneControlsView alloc] initWithFrame:frame];
	self.controlsView.sceneManager = app.sceneManager;
	
	// set up menu buttons
	self.menuViewController = [[MenuViewController alloc] init];

	// start keygrabber
	keyGrabberView = [[KeyGrabberView alloc] init];
	keyGrabberView.active = YES;
	keyGrabberView.delegate = self;
	[self.view addSubview:keyGrabberView];

	// set title here since view hasn't been inited when opening on iPhone
	if(Util.isDeviceAPhone) {
		self.navigationItem.title = self.sceneManager.scene.name;
	}
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

// called when view bounds change (after rotations, etc)
- (void)viewDidLayoutSubviews {

	// update background, if set
	if(self.background) {
		self.background.frame = self.view.bounds;
	}

	// update parent, orient, and reshape scene
	[self.sceneManager updateParent:self.view];
	[self updateOrientation];
	[self.sceneManager reshapeToParentSize:self.view.bounds.size];

	// update on screen controls
	[self updateControls];
	self.navigationItem.title = self.sceneManager.scene.name;

	// needed for autolayout
	[self.view layoutSubviews];
}

// lock orientation based on scene's preferred orientation mask
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if(self.sceneManager.scene && !self.sceneManager.isRotated) {
		return self.sceneManager.scene.preferredOrientations;
	}
	return UIInterfaceOrientationMaskAll;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
	return UIRectEdgeAll;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
	return YES;
}

#pragma mark Scene Management

- (void)openScene:(NSString *)path withType:(NSString *)type {

	// set the scenemanager here since iPhone dosen't load view until *after* this is called
	if(!self.sceneManager) {
		AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
		self.sceneManager = app.sceneManager;
	}
	
	if([self.sceneManager openScene:path withType:type forParent:self.view]) {
		
		// does the scene need key events?
		keyGrabberView.active = self.sceneManager.scene.requiresKeys;
		LogVerbose(@"PatchViewController: %@ key grabber",
			(keyGrabberView.active ? @"enabled" : @"disabled"));
	
		// set nav controller title
		self.navigationItem.title = self.sceneManager.scene.name;

		// make sure controls are updated and nav bar buttons are created
		[self updateControls];
		
		// don't need background anymore
		if(self.background) {
			[self removeBackground];
		}
	}
	else {
		// didn't open so bail out
		if(Util.isDeviceAPhone) {
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
	
	// hide iPad browser popover on selection
	[self dismissMasterPopover];
	[self dismissControlsPopover]; // controls popover too
}

- (void)closeScene {
	[self.sceneManager closeScene];
}

#pragma mark UI

// remove button item to hide on iPad
- (void)setHidesBackButton:(BOOL)hidesBackButton {
	_hidesBackButton = hidesBackButton;
	[self.navigationItem setHidesBackButton:hidesBackButton animated:YES];
	if([Util isDeviceATablet]) {
		self.navigationItem.leftBarButtonItem = (hidesBackButton ? nil : self.splitViewController.displayModeButtonItem);
	}
}

- (void)setHidesControlsButton:(BOOL)hidesControlsButton {
	_hidesControlsButton = hidesControlsButton;
	self.navigationItem.rightBarButtonItem = (hidesControlsButton ? nil : self.controlsBarButtonItem);
}

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

// cause transition to info view
- (void)infoNavButtonPressed:(id)sender {
	[self performSegueWithIdentifier:@"showInfo" sender:self];
}

- (void)dismissMasterPopover{
	self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
}

#pragma mark Touches

// persistent touch ids from ofxIPhone:
// https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiPhone/src/core/ofxiOSEAGLView.mm
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		int touchIndex = 0;
		while([[activeTouches allValues] containsObject:[NSNumber numberWithInt:touchIndex]]) {
			touchIndex++;
		}
		[activeTouches setObject:[NSNumber numberWithInt:touchIndex]
		                  forKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			#ifdef DEBUG_TOUCH
				LogVerbose(@"touch %d: down %.4f %.4f %.4f %.4f",
					touchIndex+1, pos.x, pos.y, touch.majorRadius,
					touch.force/touch.maximumPossibleForce);
			#endif
			[self.sceneManager sendEvent:RJ_TOUCH_DOWN forTouch:touch
			                   withIndex:touchIndex atPosition:pos];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		int touchIndex = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			#ifdef DEBUG_TOUCH
				LogVerbose(@"touch %d: moved %.4f %.4f %.4f %.4f",
				touchIndex+1, pos.x, pos.y, touch.majorRadius,
				touch.force/touch.maximumPossibleForce);
			#endif
			[self.sceneManager sendEvent:RJ_TOUCH_XY forTouch:touch
			                   withIndex:touchIndex atPosition:pos];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		int touchIndex = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		[activeTouches removeObjectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		CGPoint pos = [touch locationInView:self.view];
		if([self.sceneManager.scene scaleTouch:touch forPos:&pos]) {
			#ifdef DEBUG_TOUCH
				LogVerbose(@"touch %d: up %.4f %.4f %.4f %.4f",
				touchIndex+1, pos.x, pos.y, touch.majorRadius,
				touch.force/touch.maximumPossibleForce);
			#endif
			[self.sceneManager sendEvent:RJ_TOUCH_UP forTouch:touch
			                   withIndex:touchIndex atPosition:pos];
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

- (void)keyReleased:(int)key {
	[self.sceneManager sendKeyUp:key];
}

- (void)keyName:(NSString *)name pressed:(BOOL)pressed {
	[self.sceneManager sendKeyName:name pressed:pressed];
}

#pragma mark UISplitViewControllerDelegate

// toggle between hidden or overlay only
- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc {
	switch(svc.displayMode) {
		case UISplitViewControllerDisplayModePrimaryHidden:
			return UISplitViewControllerDisplayModePrimaryOverlay;
		default:
			return UISplitViewControllerDisplayModePrimaryHidden;
	}
}

// set browser back button and hide controls popover when browser is shown
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
	if(displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
		[self dismissControlsPopover];
		// re-add unless button should be hidden
		self.navigationItem.leftBarButtonItem = (self.navigationItem.hidesBackButton ? nil : self.splitViewController.displayModeButtonItem);
	}
	else { // PrimaryOverlay
		self.navigationItem.leftBarButtonItem = nil;
	}
}

#pragma mark Private

- (void)updateOrientation {

	// rotates toward home button on bottom or left
	UIInterfaceOrientation currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
	if((self.sceneManager.scene.preferredOrientations == UIInterfaceOrientationMaskAll) ||
	   (self.sceneManager.scene.preferredOrientations == UIInterfaceOrientationMaskAllButUpsideDown)) {
		[(PatchView *)self.view setRotation:0];
		self.sceneManager.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
	}
	else if(UIInterfaceOrientationIsLandscape(currentOrientation)) {
		if(self.sceneManager.scene.preferredOrientations & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown)) {
			LogVerbose(@"PatchViewController: rotating view to portrait for current scene");
			if(currentOrientation == UIInterfaceOrientationLandscapeLeft) {
				[(PatchView *)self.view setRotation:90];
				self.sceneManager.currentOrientation = UIInterfaceOrientationLandscapeLeft;
			}
			else {
				[(PatchView *)self.view setRotation:-90];
				self.sceneManager.currentOrientation = UIInterfaceOrientationLandscapeRight;
			}
		}
		else {
			[(PatchView *)self.view setRotation:0];
			self.sceneManager.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
	}
	else { // default is portrait
		if(self.sceneManager.scene.preferredOrientations & UIInterfaceOrientationMaskLandscape) {
			LogVerbose(@"PatchViewController: rotating view to landscape for current scene");
			if(currentOrientation == UIInterfaceOrientationPortrait) {
				[(PatchView *)self.view setRotation:-90];
				self.sceneManager.currentOrientation = UIInterfaceOrientationPortrait;
			}
			else {
				[(PatchView *)self.view setRotation:90];
				self.sceneManager.currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
			}
		}
		else {
			[(PatchView *)self.view setRotation:0];
			self.sceneManager.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
	}
	self.sceneManager.isRotated = ([(PatchView *)self.view rotation] != 0);

	// iOS 16+ requires the following to know when to update rotation, otherwise
	// the view ends up "dancing" when rotation re-triggers itself in a loop
	if(@available(iOS 16.0, *)) {
		[self setNeedsUpdateOfSupportedInterfaceOrientations];
	}
}

- (void)updateControls {
	if(self.navigationItem.hidesBackButton != self.hidesBackButton) {
		[self.navigationItem setHidesBackButton:self.hidesBackButton animated:YES];
	}

	if(!self.sceneManager.scene.requiresControls) {
		[self.controlsView removeFromSuperview];
		[self dismissControlsPopover];
		self.controlsPopover = nil;
		return;
	}

	if(self.sceneManager.scene.requiresOnscreenControls) {

		// make sure to close popover if it's still visible on iPad
		if(self.controlsPopover) {
			[self dismissControlsPopover];
			self.controlsPopover = nil;
		}

		// controls should be on screen at the bottom of the view
		if(!self.controlsView.superview) {

			// make sure the color is black as it might have been white in a popover
			self.controlsView.lightBackground = NO;
			
			// create nav button if the scene has any info to show
			if(self.sceneManager.scene.hasInfo && !self.hidesControlsButton) {
				self.navigationItem.rightBarButtonItem = self.infoBarButtonItem;
			}
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
			
			// larger sizing for iPad
			if(Util.isDeviceATablet) {
				[self.controlsView defaultSize];
			}
			
			[self.view addSubview:self.controlsView];
			[self.controlsView alignToSuperviewBottom];
			[self.controlsView updateControls];
		}
		self.controlsView.height = CGRectGetHeight(self.view.bounds) - self.sceneManager.scene.contentHeight;
	}
	else {
	
		// controls should be in a popup activated from a nav button
		if(!self.controlsPopover && self.sceneManager.scene) {
			[self.controlsView removeFromSuperview];
			
			// white background for popover
			self.controlsView.lightBackground = YES;
			
			// create nav button
			if(!self.hidesControlsButton) {
				self.navigationItem.rightBarButtonItem = self.controlsBarButtonItem;
			}
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
			
			// smaller controls in iPad popover
			if(Util.isDeviceATablet) {
				[self.controlsView halfSize];
			}
				
			// create popover with controls & menu
			int width = ControlsView.baseWidth;
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
			[self.controlsView updateControls];
		}
	}
}

- (void)dismissControlsPopover {
	if(self.controlsPopover.popoverVisible) {
		[self.controlsPopover dismissPopoverAnimated:YES];
	}
}

- (void)addBackground {
	self.background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash"]];
	self.background.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:self.background];
}

- (void)removeBackground {
	[self.background removeFromSuperview];
	self.background = nil;
}

- (UIBarButtonItem *)controlsBarButtonItem {
	UIBarButtonItem *button =
		[[UIBarButtonItem alloc] initWithTitle:nil
										 style:UIBarButtonItemStylePlain
										target:self
										action:@selector(controlsNavButtonPressed:)];
	button.image = [UIImage imageNamed:@"controls"];
	if(!button.image) { // fallback
		button.title = @"Controls";
	}
	return button;
}

- (UIBarButtonItem *)infoBarButtonItem {
	UIBarButtonItem *button =
		[[UIBarButtonItem alloc] initWithTitle:nil
										 style:UIBarButtonItemStylePlain
										target:self
										action:@selector(infoNavButtonPressed:)];
	button.image = [UIImage imageNamed:@"info"];
	if(!button.image) { // fallback
		button.title = @"Info";
	}
	return button;
}

@end
