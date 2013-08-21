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

- (void)awakeFromNib {
	activeTouches = [[NSMutableDictionary alloc] init];
	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// start keygrabber
	grabber = [[KeyGrabberView alloc] init];
	grabber.active = YES;
	grabber.delegate = self;
	[self.view addSubview:grabber];

	// set the scenemanager here since iPhone dosen't load view until *after* this is called
	if(!self.sceneManager) {
		AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		self.sceneManager = app.sceneManager;
	}

	// hide rj controls by default
	self.rjControlsView.hidden = YES;
	
	// update scene manager pointers for new patch controller view (if new)
	if(![Util isDeviceATablet]) {
		[self.sceneManager updateParent:self.view andControls:self.rjControlsView];
	}
	
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleDefault];
}

- (void)dealloc {
	// clear pointers when the view is popped
	[self.sceneManager updateParent:nil andControls:nil];
}

- (void)viewDidLayoutSubviews {
	// update scene manager pointers for new patch controller view (if new)
	if([Util isDeviceATablet]) {
		[self.sceneManager updateParent:self.view andControls:self.rjControlsView];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.sceneManager rotated:fromInterfaceOrientation to:self.interfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// lock iPhone to portrait for RjDj scenes, allow rotation for all others
- (NSUInteger)supportedInterfaceOrientations {
	if(![Util isDeviceATablet] && self.sceneManager.scene.type == SceneTypeRj) {
		return UIInterfaceOrientationMaskPortrait;
	}
	return UIInterfaceOrientationMaskAll;
}

- (void)openScene:(NSString*)path withType:(SceneType)type {

	// set the scenemanager here since iPhone dosen't load view until *after* this is called
	if(!self.sceneManager) {
		AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		self.sceneManager = app.sceneManager;
	}
	
	if([self.sceneManager openScene:path withType:type forParent:self.view andControls:self.rjControlsView]) {
		
		// turn up volume & turn on transport, update gui
		[self updateRjControls];
		
		// does the scene need key events?
		grabber.active = self.sceneManager.scene.requiresKeys;
		DDLogVerbose(@"PatchViewController: %@ key grabber", grabber.active ? @"enabled" : @"disabled");
	
		// set nav controller title
		self.navigationItem.title = self.sceneManager.scene.name;
	
		// hide iPad browser popover on selection 
		if(self.masterPopoverController != nil) {
			[self.masterPopoverController dismissPopoverAnimated:YES];
		}
	}
}

- (void)closeScene {
	[self.sceneManager closeScene];
	[self.rjRecordButton setTitle:@"Record"];
}

#pragma mark RJ Controls

- (IBAction)rjControlChanged:(id)sender {
	if(sender == self.rjPauseButton) {
		//DDLogInfo(@"RJ Pause button pressed: %d", self.rjPauseButton.isSelected);
		self.sceneManager.pureData.audioEnabled = !self.sceneManager.pureData.audioEnabled;
		if(self.sceneManager.pureData.audioEnabled) {
			[self.rjPauseButton setTitle:@"Pause"];
		}
		else {
			[self.rjPauseButton setTitle:@"Play"];
		}
	}
	else if(sender == self.rjRecordButton) {
		//DDLogInfo(@"RJ Record button pressed: %d", self.rjRecordButton.isSelected);
		if(!self.sceneManager.pureData.isRecording) {
			
			NSString *recordDir = [[Util documentsPath] stringByAppendingPathComponent:@"recordings"];
			if(![[NSFileManager defaultManager] fileExistsAtPath:recordDir]) {
				DDLogVerbose(@"Recordings dir not found, creating %@", recordDir);
				NSError *error;
				if(![[NSFileManager defaultManager] createDirectoryAtPath:recordDir withIntermediateDirectories:NO attributes:nil error:&error]) {
					DDLogError(@"Couldn't create %@, error: %@", recordDir, error.localizedDescription);
					return;
				}
			}
			
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yy-MM-dd_hhmmss"];
			NSString *date = [formatter stringFromDate:[NSDate date]];
			[self.sceneManager.pureData startRecordingTo:[recordDir stringByAppendingPathComponent:[self.sceneManager.scene.name stringByAppendingFormat:@"_%@.wav", date]]];
			[self.rjRecordButton setTitle:@"Stop"];
		}
		else {
			[self.sceneManager.pureData stopRecording];
			[self.rjRecordButton setTitle:@"Record"];
		}
	}
	else if(sender == self.rjInputLevelSlider) {
		//DDLogInfo(@"RJ Input level slider changed: %f", self.rjInputLevelSlider.value);
		self.sceneManager.pureData.micVolume = self.rjInputLevelSlider.value;
	}
}

- (void)updateRjControls {
	
	if(self.sceneManager.pureData.audioEnabled) {
		[self.rjPauseButton setTitle:@"Pause"];
	}
	else {
		[self.rjPauseButton setTitle:@"Play"];
	}
	
	if(self.sceneManager.pureData.isRecording) {
		[self.rjRecordButton setTitle:@"Stop"];
	}
	else {
		[self.rjRecordButton setTitle:@"Record"];
	}
	
	self.rjInputLevelSlider.value = self.sceneManager.pureData.micVolume;
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
