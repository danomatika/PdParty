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
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
	
	app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	
	self.oscAccelEnabledSwitch.on = app.osc.accelSendingEnabled;
	self.oscTouchEnabledSwitch.on = app.osc.touchSendingEnabled;
	self.oscRotationEnabledSwitch.on = app.osc.rotationSendingEnabled;
	self.oscKeyEnabledSwitch.on = app.osc.keySendingEnabled;
	
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

#pragma mark OSC

- (IBAction)oscEventTypeChanged:(id)sender {
	if(sender == self.oscAccelEnabledSwitch) {
		app.osc.accelSendingEnabled = self.oscAccelEnabledSwitch.isOn;
	}
	else if(sender == self.oscTouchEnabledSwitch) {
		app.osc.touchSendingEnabled = self.oscTouchEnabledSwitch.isOn;
	}
	else if(sender == self.oscRotationEnabledSwitch) {
		app.osc.rotationSendingEnabled = self.oscRotationEnabledSwitch.isOn;
	}
	else if(sender == self.oscKeyEnabledSwitch) {
		app.osc.keySendingEnabled = self.oscKeyEnabledSwitch.isOn;
	}
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
