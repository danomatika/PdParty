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
	
	self.oscAccelEnabledSwitch.on = app.osc.accelSendingEnabled;
	self.oscTouchEnabledSwitch.on = app.osc.touchSendingEnabled;
	self.oscLocationEnabledSwitch.on = app.osc.locateSendingEnabled;
	self.oscKeyEnabledSwitch.on = app.osc.keySendingEnabled;
	self.oscPrintEnabledSwitch.on = app.osc.printSendingEnabled;
	
	ticksPerBufferValues = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:4],
		[NSNumber numberWithInt:8], [NSNumber numberWithInt:16], [NSNumber numberWithInt:32], nil];
	for(int i = ticksPerBufferValues.count-1; i > 0; --i) {
		NSNumber *value = [ticksPerBufferValues objectAtIndex:i];
		if(app.pureData.ticksPerBuffer >= [value intValue]) {
			self.ticksPerBufferSegmentedControl.selectedSegmentIndex = i;
			break;
		}
	}
	self.latencyLabel.text = [NSString stringWithFormat:@"%.1f ms", [app.pureData calculateLatency]];
	
	self.libFolderSpinner.hidden = YES;
	self.samplesFolderSpinner.hidden = YES;
	self.testsFolderSpinner.hidden = YES;
	
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// lock orientation
- (NSUInteger)supportedInterfaceOrientations {
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
}

#pragma mark OSC Event Forwarding

- (IBAction)oscEventTypeChanged:(id)sender {
	if(sender == self.oscAccelEnabledSwitch) {
		app.osc.accelSendingEnabled = self.oscAccelEnabledSwitch.isOn;
	}
	else if(sender == self.oscTouchEnabledSwitch) {
		app.osc.touchSendingEnabled = self.oscTouchEnabledSwitch.isOn;
	}
	else if(sender == self.oscLocationEnabledSwitch) {
		app.osc.locateSendingEnabled = self.oscLocationEnabledSwitch.isOn;
	}
	else if(sender == self.oscKeyEnabledSwitch) {
		app.osc.keySendingEnabled = self.oscKeyEnabledSwitch.isOn;
	}
	else if(sender == self.oscPrintEnabledSwitch) {
		app.osc.printSendingEnabled = self.oscPrintEnabledSwitch.isOn;
	}
}

#pragma mark Audio Latency

- (IBAction)ticksPerBufferChanged:(id)sender {
	// get value from array
	int index = self.ticksPerBufferSegmentedControl.selectedSegmentIndex;
	app.pureData.ticksPerBuffer = [[ticksPerBufferValues objectAtIndex:index] integerValue];
	self.latencyLabel.text = [NSString stringWithFormat:@"%.1f ms", [app.pureData calculateLatency]];
}

#pragma mark Default Folders

- (IBAction)copyDefaultFolder:(id)sender {
	if(sender == self.libFolderButton) {
		self.libFolderButton.enabled = NO;
		self.libFolderSpinner.hidden = NO;
		[self.libFolderSpinner startAnimating];
		[app copyLibFolder];
		self.libFolderSpinner.hidden = YES;
		self.libFolderButton.enabled = YES;
		[self.libFolderSpinner stopAnimating];
	}
	else if(sender == self.samplesFolderButton) {
		self.samplesFolderButton.enabled = NO;
		self.samplesFolderSpinner.hidden = NO;
		[self.samplesFolderSpinner startAnimating];
		[app copySamplesFolder];
		self.samplesFolderSpinner.hidden = YES;
		self.samplesFolderButton.enabled = YES;
		[self.samplesFolderSpinner stopAnimating];
	}
	else if(sender == self.testsFolderButton) {
		self.testsFolderButton.enabled = NO;
		self.testsFolderSpinner.hidden = NO;
		[self.testsFolderSpinner startAnimating];
		[app copyTestsFolder];
		self.testsFolderSpinner.hidden = YES;
		self.testsFolderButton.enabled = YES;
		[self.testsFolderSpinner stopAnimating];
	}
}

@end
