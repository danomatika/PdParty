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
#import "SettingsViewController.h"

#import "MBProgressHUD.h"

#import "Osc.h"
#import "AppDelegate.h"

@interface SettingsViewController () {
	AppDelegate *app;
	NSArray *ticksPerBufferValues;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
	
	app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	
	self.lockScreenDisabledSwitch.on = app.isLockScreenDisabled;
	self.runInBackgroundSwitch.on = app.runsInBackground;
	self.enableConsoleSwitch.on = [Log textViewLoggerEnabled];
	
	self.oscTouchEnabledSwitch.on = app.osc.touchSendingEnabled;
	self.oscSensorEnabledSwitch.on = app.osc.sensorSendingEnabled;
	self.oscKeyEnabledSwitch.on = app.osc.keySendingEnabled;
	self.oscPrintEnabledSwitch.on = app.osc.printSendingEnabled;
	
	self.autoLatencySwitch.on = app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.enabled = !app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.userInteractionEnabled = !app.pureData.autoLatency;
	ticksPerBufferValues = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:4],
		[NSNumber numberWithInt:8], [NSNumber numberWithInt:16], [NSNumber numberWithInt:32], nil];
	for(int i = 0; i < (int)ticksPerBufferValues.count; ++i) {
		NSNumber *value = [ticksPerBufferValues objectAtIndex:i];
		if(app.pureData.ticksPerBuffer <= [value intValue]) {
			self.ticksPerBufferSegmentedControl.selectedSegmentIndex = i;
			break;
		}
	}
	[self updateLatencyLabel];
	
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Behavior

- (IBAction)behaviorChanged:(id)sender {
	if(sender == self.lockScreenDisabledSwitch) {
		app.lockScreenDisabled = self.lockScreenDisabledSwitch.isOn;
	}
	else if(sender == self.runInBackgroundSwitch) {
		app.runsInBackground = self.runInBackgroundSwitch.isOn;
	}
	else if(sender == self.enableConsoleSwitch) {
		[Log enableTextViewLogger:self.enableConsoleSwitch.isOn];
	}
}

#pragma mark OSC Event Forwarding

- (IBAction)oscEventTypeChanged:(id)sender {
	if(sender == self.oscTouchEnabledSwitch) {
		app.osc.touchSendingEnabled = self.oscTouchEnabledSwitch.isOn;
	}
	else if(sender == self.oscSensorEnabledSwitch) {
		app.osc.sensorSendingEnabled = self.oscSensorEnabledSwitch.isOn;
	}
	else if(sender == self.oscKeyEnabledSwitch) {
		app.osc.keySendingEnabled = self.oscKeyEnabledSwitch.isOn;
	}
	else if(sender == self.oscPrintEnabledSwitch) {
		app.osc.printSendingEnabled = self.oscPrintEnabledSwitch.isOn;
	}
}

#pragma mark Audio Latency

- (IBAction)autoLatencyChanged:(id)sender {
	app.pureData.autoLatency = self.autoLatencySwitch.isOn;
	self.ticksPerBufferSegmentedControl.enabled = !app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.userInteractionEnabled = !app.pureData.autoLatency;
	//self.ticksPerBufferSegmentedControl.tintColor = [UIColor grayColor];
}

- (IBAction)ticksPerBufferChanged:(id)sender {
	// get value from array
	int index = (int)self.ticksPerBufferSegmentedControl.selectedSegmentIndex;
	app.pureData.ticksPerBuffer = [[ticksPerBufferValues objectAtIndex:index] intValue];
	[self updateLatencyLabel];
}

#pragma mark Default Folders

- (IBAction)copyDefaultFolder:(id)sender {
	UIView *root = app.window.rootViewController.view;
	if([Util isDeviceATablet]) {
		root = self.view; // present over this view on iPad to make sure hud is not presented under detail view
	}
	if(sender == self.libFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.labelText = @"Copying lib folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[app copyLibDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hide:YES];
			});
		});
	}
	else if(sender == self.samplesFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.labelText = @"Copying samples folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[app copySamplesDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hide:YES];
			});
		});
	}
	else if(sender == self.testsFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.labelText = @"Copying tests folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[app copyTestsDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hide:YES];
			});
		});
	}
}

#pragma mark Private

- (void)updateLatencyLabel {
	self.latencyLabel.text = [NSString stringWithFormat:@"%.1f ms @ %d Hz",
		[app.pureData calculateLatency], app.pureData.sampleRate];
}

@end
