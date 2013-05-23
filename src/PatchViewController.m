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
#import "PdFile.h"
#import "KeyGrabber.h"
#import "AppDelegate.h"

#define ACCEL_UPDATE_HZ	60.0

@interface PatchViewController () {

	NSMutableDictionary *activeTouches; // for persistent ids
	CMMotionManager *motionManager; // for accel data
	Osc *osc; // to send osc
	
	UIImageView *background; // for Rj scenes

	BOOL hasReshaped; // has the gui been reshaped?
}

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

// reshape the background and view controls of an rj scene
- (void)reshapeRjScene;

@end

@implementation PatchViewController

- (void)awakeFromNib {
	self.sceneType = SceneTypeEmpty;
	activeTouches = [[NSMutableDictionary alloc] init];
	hasReshaped = NO;
	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// hide rj controls by default
	self.rjControlsView.hidden = YES;
	
	// start keygrabber
	KeyGrabberView *grabber = [[KeyGrabberView alloc] init];
	grabber.active = YES;
	grabber.delegate = self;
	[self.view addSubview:grabber];
	
	// set motionManager pointer for accel updates
	AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	motionManager = app.motionManager;
	self.enableAccelerometer = YES;
	
	// set osc pointer
	osc = app.osc;
	
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleDefault];
}

- (void)viewDidLayoutSubviews {
	
	self.gui.bounds = self.view.bounds;
		
	// do animations if gui has already been setup once
	// http://www.techotopia.com/index.php/Basic_iOS_4_iPhone_Animation_using_Core_Animation
	if(hasReshaped) {
		[UIView beginAnimations:nil context:nil];
	}
	[self.gui reshapeWidgets];
	[self reshapeRjScene];
	if(hasReshaped) {
		[UIView commitAnimations];
	}
	else {
		hasReshaped = YES;
	}
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
	[PureData sendRotate:rotate newOrientation:orient];
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
	if(![Util isDeviceATablet] && self.sceneType == SceneTypeRj) {
		return UIInterfaceOrientationMaskPortrait;
	}
	return UIInterfaceOrientationMaskAll;
}

#pragma mark Overridden Getters / Setters

- (void)setPatch:(NSString*)newPatch {
    
	if(_patch != newPatch) {
        _patch = newPatch;
		
		// create gui here as iPhone dosen't load view until *after* this is called
		if(!self.gui) {
			self.gui = [[Gui alloc] init];
			self.gui.bounds = self.view.bounds;
		}
		
		// close open patch
		if(self.gui.patch) {
			[self.gui.patch closeFile];
			for(Widget *widget in self.gui.widgets) {
				[widget removeFromSuperview];
			}
			[self.gui.widgets removeAllObjects];
			self.gui.patch = nil;
			
			if(self.sceneType == SceneTypeRj && background) {
				background = nil;
			}
		}
		
		// open new patch
		if(self.patch) {
			
			NSString *fileName = [self.patch lastPathComponent];
			NSString *dirPath = [self.patch stringByDeletingLastPathComponent];
			
			if(![[NSFileManager defaultManager] fileExistsAtPath:newPatch]) {
				DDLogError(@"PatchViewController: patch does not exist: %@", newPatch);
				self.sceneType = SceneTypeEmpty;
				return;
			}
			
			DDLogVerbose(@"Opening %@ %@", fileName, dirPath);
			if(self.sceneType == SceneTypeRj) { // set view title based on scene/patch name
				self.navigationItem.title = [[dirPath lastPathComponent] stringByDeletingPathExtension];
			}
			else {
				self.navigationItem.title = [fileName stringByDeletingPathExtension];
			}
			
			DDLogVerbose(@"SceneType: %@", [PatchViewController sceneTypeAsString:self.sceneType]);
			
			// load gui for non rj scenes
			if(self.sceneType != SceneTypeRj) {
			
				// set patch view background color
				self.view.backgroundColor = [UIColor whiteColor];
			
				// load widgets from gui
				[self.gui addWidgetsFromPatch:self.patch];
				self.gui.patch = [PdFile openFileNamed:fileName path:dirPath];
				DDLogVerbose(@"Adding %d widgets", self.gui.widgets.count);
				for(Widget *widget in self.gui.widgets) {
					[widget replaceDollarZerosForGui:self.gui];
					[self.view addSubview:widget];
				}
				hasReshaped = NO;
				
				// hide rj controls & delete rj background
				self.rjControlsView.hidden = YES;
				if(background) {
					[background removeFromSuperview];
					background = nil;
				}
			}
			else { // set background and enable controls for rj scenes
				self.gui.patch = [PdFile openFileNamed:fileName path:dirPath];
			
				// set patch view background color
				self.view.backgroundColor = [UIColor blackColor];
				
				// set background
				NSString *backgroundPath = [dirPath stringByAppendingPathComponent:@"image.jpg"];
				if([[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
					background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
					if(!background.image) {
						DDLogError(@"PatchViewController: couldn't load background image");
					}
					[self.view addSubview:background];
				}
				else {
					DDLogWarn(@"PatchViewController: no background image");
				}
				
				[self.view bringSubviewToFront:self.rjControlsView];
				self.rjControlsView.hidden = NO;
				
				[self reshapeRjScene];
			}
		}
		else {
			self.sceneType = SceneTypeEmpty;
		}
    }

    if(self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
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

+ (NSString*)sceneTypeAsString:(SceneType)type {
	switch(type) {
		case SceneTypeDroid:
			return @"DroidParty";
		case SceneTypeRj:
			return @"RjDj";
		case SceneTypeParty:
			return @"PdParty";
		case SceneTypePatch:
			return @"Patch";
		default: // Empty
			return @"Empty";
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
	}
	else { // stop
		if([motionManager isAccelerometerActive]) {
          [motionManager stopAccelerometerUpdates];
		}
	}
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
		while([[activeTouches allValues] containsObject:[NSNumber numberWithInt:touchId]]){
			touchId++;
		}
		[activeTouches setObject:[NSNumber numberWithInt:touchId]
						  forKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		pos.x = pos.x/CGRectGetWidth(self.view.frame);
		pos.y = pos.y/CGRectGetHeight(self.view.frame);
			
		// normalize
		if(self.sceneType == SceneTypeRj) {
			pos.x = (int)(pos.x * 320);
			pos.y = (int)(pos.y * 320);
		}
		
//		DDLogVerbose(@"touch %d: down %.4f %.4f", touchId+1, pos.x, pos.y);
		[PureData sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
		if(osc.isListening) {
			[osc sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		
		CGPoint pos = [touch locationInView:self.view];
		pos.x = pos.x/CGRectGetWidth(self.view.frame);
		pos.y = pos.y/CGRectGetHeight(self.view.frame);
			
		// normalize
		if(self.sceneType == SceneTypeRj) {
			pos.x = (int)(pos.x * 320);
			pos.y = (int)(pos.y * 320);
		}
		
//		DDLogVerbose(@"touch %d: moved %d %d", touchId+1, (int) pos.x, (int) pos.y);
		[PureData sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
		if(osc.isListening) {
			[osc sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		[activeTouches removeObjectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		pos.x = pos.x/CGRectGetWidth(self.view.frame);
		pos.y = pos.y/CGRectGetHeight(self.view.frame);
		
		// normalize
		if(self.sceneType == SceneTypeRj) {
			pos.x = (int)(pos.x * 320);
			pos.y = (int)(pos.y * 320);
		}
		
//		DDLogVerbose(@"touch %d: up %d %d", touchId+1, (int) pos.x, (int) pos.y);
		[PureData sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
		if(osc.isListening) {
			[osc sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
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

#pragma Private

- (void)reshapeRjScene {
	if(!self.sceneType == SceneTypeRj) {
		return;
	}
	
	CGSize viewSize, backgroundSize, controlsSize;
	CGFloat xPos = 0;
	
	// rj backgrounds are always square
	viewSize = self.view.frame.size;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
		backgroundSize.width = viewSize.width;
		backgroundSize.height = backgroundSize.width;
	}
	else {
		backgroundSize.width = viewSize.height * 0.8;
		backgroundSize.height = backgroundSize.width;
		xPos = (viewSize.width - backgroundSize.width)/2;
	}
	
	// set background
	if(background) {
		background.frame = CGRectMake(xPos, 0, backgroundSize.width, backgroundSize.height);
	}
	
	// set controls
	controlsSize.width = backgroundSize.width;
	controlsSize.height = CGRectGetHeight(self.view.bounds) - backgroundSize.height;
	self.rjControlsView.frame = CGRectMake(0, backgroundSize.height, controlsSize.width, controlsSize.height);
}

@end
