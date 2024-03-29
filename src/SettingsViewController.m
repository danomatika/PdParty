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
	NSArray *sampleRateValues;
	NSArray *ticksPerBufferValues;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
	
	app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	
	self.lockScreenDisabledSwitch.on = app.isLockScreenDisabled;
	self.runInBackgroundSwitch.on = app.runsInBackground;
	self.enableConsoleSwitch.on = Log.textViewLoggerEnabled;
	
	self.oscTouchEnabledSwitch.on = app.osc.touchSendingEnabled;
	self.oscSensorEnabledSwitch.on = app.osc.sensorSendingEnabled;
	self.oscControllersEnabledSwitch.on = app.osc.controllerSendingEnabled;
	self.oscKeyEnabledSwitch.on = app.osc.keySendingEnabled;
	self.oscPrintEnabledSwitch.on = app.osc.printSendingEnabled;

	sampleRateValues = @[@(48000), @(44100), @(96000)];
	int userSampleRate = [app.pureData userSampleRate];
	for(int i = 0; i < (int)sampleRateValues.count; ++i) {
		NSNumber *value = sampleRateValues[i];
		if(userSampleRate == [value intValue]) {
			self.sampleRateSegmentedControl.selectedSegmentIndex = i;
			break;
		}
	}

	self.autoLatencySwitch.on = app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.enabled = !app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.userInteractionEnabled = !app.pureData.autoLatency;
	ticksPerBufferValues = @[@(1), @(2), @(4), @(8), @(16), @(32)];
	for(int i = 0; i < (int)ticksPerBufferValues.count; ++i) {
		NSNumber *value = ticksPerBufferValues[i];
		if(app.pureData.ticksPerBuffer <= [value intValue]) {
			self.ticksPerBufferSegmentedControl.selectedSegmentIndex = i;
			break;
		}
	}
	[self updateLatencyLabel];
	
	[super viewDidLoad];
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
	else if(sender == self.oscControllersEnabledSwitch) {
		app.osc.controllerSendingEnabled = self.oscControllersEnabledSwitch.isOn;
	}
	else if(sender == self.oscShakeEnabledSwitch) {
		app.osc.shakeSendingEnabled = self.oscShakeEnabledSwitch.isOn;
	}
	else if(sender == self.oscKeyEnabledSwitch) {
		app.osc.keySendingEnabled = self.oscKeyEnabledSwitch.isOn;
	}
	else if(sender == self.oscPrintEnabledSwitch) {
		app.osc.printSendingEnabled = self.oscPrintEnabledSwitch.isOn;
	}
}

#pragma mark Audio Sample Rate

- (IBAction)sampleRateChanged:(id)sender {
	// get value from array
	int index = (int)self.sampleRateSegmentedControl.selectedSegmentIndex;
	int sampleRate = [sampleRateValues[index] intValue];
	app.pureData.userSampleRate = sampleRate;
	if(app.sceneManager.scene.sampleRate == USER_SAMPLERATE) {
		app.pureData.sampleRate = sampleRate;
	}
}

#pragma mark Audio Latency

- (IBAction)autoLatencyChanged:(id)sender {
	app.pureData.autoLatency = self.autoLatencySwitch.isOn;
	self.ticksPerBufferSegmentedControl.enabled = !app.pureData.autoLatency;
	self.ticksPerBufferSegmentedControl.userInteractionEnabled = !app.pureData.autoLatency;
}

- (IBAction)ticksPerBufferChanged:(id)sender {
	// get value from array
	int index = (int)self.ticksPerBufferSegmentedControl.selectedSegmentIndex;
	app.pureData.ticksPerBuffer = [ticksPerBufferValues[index] intValue];
	[self updateLatencyLabel];
}

#pragma mark Default Folders

- (IBAction)copyDefaultFolder:(id)sender {
	UIView *root = app.window.rootViewController.view;
	if(Util.isDeviceATablet) {
		root = self.view; // present over this view on iPad to make sure hud is not presented under detail view
	}
	if(sender == self.libFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.label.text = @"Copying lib folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[self->app copyLibDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hideAnimated:YES];
			});
		});
	}
	else if(sender == self.samplesFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.label.text = @"Copying samples folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[self->app copySamplesDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hideAnimated:YES];
			});
		});
	}
	else if(sender == self.testsFolderButton) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:root animated:YES];
		hud.label.text = @"Copying tests folder...";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[NSThread sleepForTimeInterval:1.0]; // time for popup to show
			[self->app copyTestsDirectory];
			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hideAnimated:YES];
			});
		});
	}
}

#pragma mark Private

- (void)updateLatencyLabel {
	self.latencyLabel.text = [NSString stringWithFormat:@"%d ms @ %d Hz",
		[app.pureData calculateLatency], app.pureData.sampleRate];
}

@end
