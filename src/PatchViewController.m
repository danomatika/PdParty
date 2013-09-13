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
#import "AppDelegate.h"

@interface PatchViewController () {
	NSMutableDictionary *activeTouches; // for persistent ids
	KeyGrabberView *grabber; // for keyboard events
}
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@end

@implementation PatchViewController

- (void)viewDidLoad {

	_rotation = 0;
	activeTouches = [[NSMutableDictionary alloc] init];
	
	// set instance pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	app.patchViewController = self;
	
	// setup controls view
	int controlsHeight = 192;
	if(![Util isDeviceATablet]) {
		controlsHeight = 96;
	}
	self.controlsView = [[ControlsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), controlsHeight)];
	self.controlsView.translatesAutoresizingMaskIntoConstraints = NO;
	self.controlsView.sceneManager = app.sceneManager;

	// start keygrabber
	grabber = [[KeyGrabberView alloc] init];
	grabber.active = YES;
	grabber.delegate = self;
	[self.view addSubview:grabber];

	// hide controls by default
	self.controlsView.hidden = YES;
	
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

	[self.sceneManager updateParent:self.view];
	
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
				[self.sceneManager rotated:currentOrientation to:UIInterfaceOrientationLandscapeLeft];
			}
			else {
				self.rotation = -90;
				[self.sceneManager rotated:currentOrientation to:UIInterfaceOrientationLandscapeRight];
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
				[self.sceneManager rotated:currentOrientation to:UIInterfaceOrientationPortrait];
			}
			else {
				self.rotation = 90;
				[self.sceneManager rotated:currentOrientation to:UIInterfaceOrientationPortraitUpsideDown];
			}
		}
		else {
			self.rotation = 0;
		}
	}
	[self.sceneManager reshapeToParentSize:self.view.bounds.size];

	// update on screen controls
	if(self.sceneManager.scene.requiresOnscreenControls) {
	
		// controls should be on screen at the bottom of the view
		if(self.controlsView.superview != self.view) {
			[self.controlsView removeFromSuperview];
			
			// add to this view
			[self.view addSubview:self.controlsView];
			self.controlsView.hidden = NO;
	
			// auto layout constraints
			[self.view addConstraints:[NSArray arrayWithObjects:
				[NSLayoutConstraint constraintWithItem:self.controlsView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
												toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0],
				[NSLayoutConstraint constraintWithItem:self.controlsView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
												toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0],
				[NSLayoutConstraint constraintWithItem:self.controlsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
												toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0], nil]];
		}
		self.controlsView.height = CGRectGetHeight(self.view.bounds) - self.sceneManager.scene.contentHeight;
	}
	else {
	
		// controls should be in a popup activated from a button
		if(self.controlsView.superview == self.view) {
			[self.controlsView removeFromSuperview];
			self.controlsView.hidden = YES;
		}
	}
	[self.controlsView updateControls];

	self.navigationItem.title = self.sceneManager.scene.name;

	[self.view setNeedsUpdateConstraints];
	[self.view layoutSubviews];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.sceneManager rotated:fromInterfaceOrientation to:self.interfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// lock orientation based on scene's preferred orientation mask
- (NSUInteger)supportedInterfaceOrientations {
	if(self.sceneManager.scene) {
		return self.sceneManager.scene.preferredOrientations;
	}
	return UIInterfaceOrientationMaskAll;
}

// only called if this is a modal view (when forcing device rotation)
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//	if(self.sceneManager.scene) {
//		int currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
//		if(self.sceneManager.scene.preferredOrientations & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown)) {
//			if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
//				return UIInterfaceOrientationPortraitUpsideDown;
//			}
//			return UIInterfaceOrientationPortrait;
//		}
//		else {
//			if(currentOrientation == UIInterfaceOrientationLandscapeLeft) {
//				return UIInterfaceOrientationLandscapeLeft;
//			}
//			return UIInterfaceOrientationLandscapeRight;
//		}
//	}
//	return UIInterfaceOrientationPortrait;
//}

#pragma mark Scene Management

- (void)openScene:(NSString *)path withType:(SceneType)type {

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
	}
	
	// hide iPad browser popover on selection 
	if(self.masterPopoverController != nil) {
		[self.masterPopoverController dismissPopoverAnimated:YES];
	}
}

- (void)closeScene {
	[self.sceneManager closeScene];
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
