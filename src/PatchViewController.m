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
#import "Gui.h"
#import "PdParser.h"
#import "AppDelegate.h"

#define ACCEL_UPDATE_HZ	60.0

@interface PatchViewController () {

	NSMutableDictionary *activeTouches; // for persistent ids
	
	CMMotionManager *motionManager; // for accel data
	KeyGrabberView *grabber; // for keyboard events
	
	Osc *osc; // to send osc
	PureData *pureData; // to set samplerate

	BOOL hasReshaped; // has the gui been reshaped?
}

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

@end

@implementation PatchViewController

- (void)awakeFromNib {
	activeTouches = [[NSMutableDictionary alloc] init];
	hasReshaped = NO;
	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// hide rj controls by default
	self.rjControlsView.hidden = YES;
	
	// start keygrabber
	grabber = [[KeyGrabberView alloc] init];
	grabber.delegate = self;
	[self.view addSubview:grabber];
	
	// set motionManager pointer for accel updates
	AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	motionManager = app.motionManager;
	
	// set osc and pure data pointer
	osc = app.osc;
	pureData = app.pureData;
	
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleDefault];
}

- (void)viewDidLayoutSubviews {
	
	self.gui.bounds = self.view.bounds;
		
	// do animations if gui has already been setup once
	// http://www.techotopia.com/index.php/Basic_iOS_4_iPhone_Animation_using_Core_Animation
	if(hasReshaped) {
		[UIView beginAnimations:nil context:nil];
	}
	[self.scene reshape];
	if(hasReshaped) {
		[UIView commitAnimations];
	}
	else {
		hasReshaped = YES;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	// close scene if the current actiuve view is changing
	[self closeScene];
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	int rotate = [PatchViewController orientationInDegrees:fromInterfaceOrientation] -
			     [PatchViewController orientationInDegrees:self.interfaceOrientation];
	
	NSString *orient;
	switch(self.interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			orient = PARTY_ORIENT_PORTRAIT;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			orient = PARTY_ORIENT_PORTRAIT_UPSIDEDOWN;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			orient = PARTY_ORIENT_LANDSCAPE_LEFT;
			break;
		case UIInterfaceOrientationLandscapeRight:
			orient = PARTY_ORIENT_LANDSCAPE_RIGHT;
			break;
	}

//	DDLogVerbose(@"rotate: %d %@", rotate, orient);
	if(self.enableRotation) {
		[PureData sendRotate:rotate newOrientation:orient];
	}
	if(osc.isListening) {
		[osc sendRotate:rotate newOrientation:orient];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// lock to portrait for RjDj scenes, allow rotation for all others
- (NSUInteger)supportedInterfaceOrientations {
	if(![Util isDeviceATablet] && self.scene.type == SceneTypeRj) {
		return UIInterfaceOrientationMaskPortrait;
	}
	return UIInterfaceOrientationMaskAll;
}

- (void)openScene:(NSString*)path withType:(SceneType)type {

	// create gui here as iPhone dosen't load view until *after* this is called
	if(!self.gui) {
		self.gui = [[Gui alloc] init];
		self.gui.bounds = self.view.bounds;
	}
	
	// close open scene
	[self closeScene];
	
	// open new scene
	switch(type) {
		case SceneTypePatch:
			self.scene = [PatchScene sceneWithParent:self.view andGui:self.gui];
			break;
		case SceneTypeRj: {
			RjScene *rj = [RjScene sceneWithParent:self.view andControls:self.rjControlsView];
			rj.dispatcher = pureData.dispatcher;
			self.scene = rj;
			break;
		}
		case SceneTypeDroid:
			self.scene = [DroidScene sceneWithParent:self.view andGui:self.gui];
			break;
		case SceneTypeParty:
			self.scene = [PartyScene sceneWithParent:self.view andGui:self.gui];
			break;
		default: // SceneTypeEmpty
			self.scene = [[Scene alloc] init];
			break;
	}
	pureData.sampleRate = self.scene.sampleRate;
	self.enableAccelerometer = self.scene.requiresAccel;
	self.enableRotation = self.scene.requiresRotation;
	self.enableKeyGrabber = self.scene.requiresKeys;
	[self.scene open:path];
	
	// set nav controller title
	self.navigationItem.title = self.scene.name;
	
	// hide iPad browser popover on selection 
	if(self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    } 
}

- (void)closeScene {
	if(self.scene) {
		[self.scene close];
		self.scene = nil;
	}
}

#pragma mark Util

+ (int)orientationInDegrees:(UIInterfaceOrientation)orientation {
	switch(orientation) {
		case UIInterfaceOrientationPortrait:
			return 0;
		case UIInterfaceOrientationPortraitUpsideDown:
			return 180;
		case UIInterfaceOrientationLandscapeLeft:
			return 90;
		case UIInterfaceOrientationLandscapeRight:
			return -90;
	}
}

#pragma mark Overridden Getters / Setters

- (void)setEnableAccelerometer:(BOOL)enableAccelerometer {
	if(self.enableAccelerometer == enableAccelerometer) {
		return;
	}
	_enableAccelerometer = enableAccelerometer;
	
	// start
	if(enableAccelerometer) {
		if([motionManager isAccelerometerAvailable]) {
			NSTimeInterval updateInterval = 1.0/ACCEL_UPDATE_HZ;
			[motionManager setAccelerometerUpdateInterval:updateInterval];
			
			// accel data callback block
			[motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
//					DDLogVerbose(@"accel %f %f %f", accelerometerData.acceleration.x,
//													accelerometerData.acceleration.y,
//													accelerometerData.acceleration.z);
					[PureData sendAccel:accelerometerData.acceleration.x
									  y:accelerometerData.acceleration.y
									  z:accelerometerData.acceleration.z];
					if(osc.isListening) {
						[osc sendAccel:accelerometerData.acceleration.x
										  y:accelerometerData.acceleration.y
										  z:accelerometerData.acceleration.z];
					}
				}];
		}
		DDLogVerbose(@"PatchViewController: enabled accel");
	}
	else { // stop
		if([motionManager isAccelerometerActive]) {
          [motionManager stopAccelerometerUpdates];
		}
		DDLogVerbose(@"PatchViewController: disabled accel");
	}
}

- (void)setEnableRotation:(BOOL)enableRotation {
	if(self.enableRotation == enableRotation) {
		return;
	}
	_enableRotation = enableRotation;
	DDLogVerbose(@"PatchViewController: %@ rotation", enableRotation ? @"enabled" : @"disabled");
}

- (void)setEnableKeyGrabber:(BOOL)enableKeyGrabber {
	if(grabber.active == enableKeyGrabber) {
		return;
	}
	grabber.active = enableKeyGrabber;
	DDLogVerbose(@"PatchViewController: %@ key grabber", enableKeyGrabber ? @"enabled" : @"disabled");
}

- (BOOL)enableKeyGrabber {
	return grabber.active;
}

#pragma mark RJ Controls

- (IBAction)rjControlChanged:(id)sender {
	if(sender == self.rjPauseButton) {
		self.rjPauseButton.selected = !self.rjPauseButton.selected;
		DDLogInfo(@"RJ Pause button pressed: %d", self.rjPauseButton.isSelected);
	}
	else if(sender == self.rjRecordButton) {
		self.rjRecordButton.selected = !self.rjRecordButton.selected;
		DDLogInfo(@"RJ Record button pressed: %d", self.rjRecordButton.isSelected);
	}
	else if(sender == self.rjInputLevelSlider) {
		DDLogInfo(@"RJ Input level slider changed: %f", self.rjInputLevelSlider.value);
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
		if([self.scene scaleTouch:touch forPos:&pos]) {
//			DDLogVerbose(@"touch %d: down %.4f %.4f", touchId+1, pos.x, pos.y);
			[PureData sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
			if(osc.isListening) {
				[osc sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		
		CGPoint pos = [touch locationInView:self.view];
		if([self.scene scaleTouch:touch forPos:&pos]) {
//			DDLogVerbose(@"touch %d: moved %d %d", touchId+1, (int) pos.x, (int) pos.y);
			[PureData sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
			if(osc.isListening) {
				[osc sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
			}
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		[activeTouches removeObjectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		if([self.scene scaleTouch:touch forPos:&pos]) {
//			DDLogVerbose(@"touch %d: up %d %d", touchId+1, (int) pos.x, (int) pos.y);
			[PureData sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
			if(osc.isListening) {
				[osc sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

#pragma mark KeyGrabberDelegate

- (void)keyPressed:(int)key {
	[PureData sendKey:key];
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
