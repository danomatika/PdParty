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
#import "PureData.h"
#import "PdParser.h"
#import "PdFile.h"
#import "KeyGrabber.h"
#import "AppDelegate.h"

@interface PatchViewController ()

@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) NSMutableDictionary *activeTouches; // for persistent ids
@property (nonatomic, weak) CMMotionManager *motionManager; // for accel data

@property (assign) BOOL hasReshaped; // has the gui been reshaped?

@end

@implementation PatchViewController

- (void)awakeFromNib {
	self.activeTouches = [[NSMutableDictionary alloc] init];
	self.hasReshaped = NO;
	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	KeyGrabberView *grabber = [[KeyGrabberView alloc] init];
	grabber.active = YES;
	grabber.delegate = self;
	[self.view addSubview:grabber];
	
	// set motionManager pointer for accel updates
	AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self.motionManager = app.motionManager;
	self.enablAccelerometer = YES;
}

- (void)viewDidLayoutSubviews {
	
	self.gui.bounds = self.view.bounds;
	
	// do animations if gui has already been setup once
	// http://www.techotopia.com/index.php/Basic_iOS_4_iPhone_Animation_using_Core_Animation
	if(self.hasReshaped) {
		[UIView beginAnimations:nil context:nil];
	}
	[self.gui reshapeWidgets];
	if(self.hasReshaped) {
		[UIView commitAnimations];
	}
	else {
		self.hasReshaped = YES;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Managing the Current Patch

- (void)setCurrentPatch:(NSString*)newPatch {
    
	if(_currentPatch != newPatch) {
        _currentPatch = newPatch;
		
		// create gui here as iPhone dosen't load view until *after* this is called
		if(!self.gui) {
			self.gui = [[Gui alloc] init];
		}
		
		// close open patch
		if(self.gui.currentPatch) {
			[self.gui.currentPatch closeFile];
			for(Widget *widget in self.gui.widgets) {
				[widget removeFromSuperview];
			}
			[self.gui.widgets removeAllObjects];
			self.gui.currentPatch = nil;
		}
		
		// open new patch
		if(self.currentPatch) {
			
			NSString *fileName = [self.currentPatch lastPathComponent];
			NSString *dirPath = [self.currentPatch stringByDeletingLastPathComponent];
			
			DDLogVerbose(@"Opening %@ %@", fileName, dirPath);
			self.navigationItem.title = [fileName stringByDeletingPathExtension]; // set view title
			
			// load gui
			[self.gui addWidgetsFromPatch:self.currentPatch];
			self.gui.currentPatch = [PdFile openFileNamed:fileName path:dirPath];
			DDLogVerbose(@"Adding %d widgets", self.gui.widgets.count);
			for(Widget *widget in self.gui.widgets) {
				[self.view addSubview:widget];
			}
			self.hasReshaped = NO;
		}
    }

    if(self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark Overridden Getters / Setters

- (void)setEnablAccelerometer:(BOOL)enablAccelerometer {
	if(self.enablAccelerometer == enablAccelerometer) {
		return;
	}
	
	_enablAccelerometer = enablAccelerometer;
	if(enablAccelerometer) { // start
		if([self.motionManager isAccelerometerAvailable]) {
			NSTimeInterval updateInterval = 1.0/60.0; // 60Hz
			[self.motionManager setAccelerometerUpdateInterval:updateInterval];
			
			// accel data callback block
			[self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
//					DDLogVerbose(@"accel %f %f %f", accelerometerData.acceleration.x,
//													accelerometerData.acceleration.y,
//													accelerometerData.acceleration.z);
					[PureData sendAccelWithX:accelerometerData.acceleration.x
										   y:accelerometerData.acceleration.y
										   z:accelerometerData.acceleration.z];
				}];
		}
	}
	else { // stop
		if([self.motionManager isAccelerometerActive]) {
          [self.motionManager stopAccelerometerUpdates];
		}
	}
}

#pragma mark Touches

// persistent touch ids from ofxIPhone:
// https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiPhone/src/core/ofxiOSEAGLView.mm
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	
	for(UITouch *touch in touches) {
		int touchId = 0;
		while([[self.activeTouches allValues] containsObject:[NSNumber numberWithInt:touchId]]){
			touchId++;
		}
		[self.activeTouches setObject:[NSNumber numberWithInt:touchId]
							   forKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		DDLogVerbose(@"touch %d: down %d %d", touchId+1, (int) pos.x, (int) pos.y);
		[PureData sendTouch:RJ_TOUCH_DOWN forId:touchId atX:pos.x andY:pos.y];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	for(UITouch *touch in touches) {
		int touchId = [[self.activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		CGPoint pos = [touch locationInView:self.view];
		DDLogVerbose(@"touch %d: moved %d %d", touchId+1, (int) pos.x, (int) pos.y);
		[PureData sendTouch:RJ_TOUCH_XY forId:touchId atX:pos.x andY:pos.y];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	for(UITouch *touch in touches) {
		int touchId = [[self.activeTouches objectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]] intValue];
		[self.activeTouches removeObjectForKey:[NSValue valueWithPointer:(__bridge const void *)(touch)]];
		
		CGPoint pos = [touch locationInView:self.view];
		DDLogVerbose(@"touch %d: up %d %d", touchId+1, (int) pos.x, (int) pos.y);
		[PureData sendTouch:RJ_TOUCH_UP forId:touchId atX:pos.x andY:pos.y];
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
