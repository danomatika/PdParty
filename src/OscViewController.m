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
#import "OscViewController.h"

#import "AppDelegate.h"
#import "WebServer.h"
#import "Util.h"

@interface OscViewController () {
	Osc *osc;
	NSTimer *oscRestartTimer;
}

/// restart the osc server
- (void)restart;

/// timer function to start the server after a gui change
- (void)startOsc:(NSTimer *)theTimer;

@end

@implementation OscViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set Osc pointer
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	osc = app.osc;
	
	self.oscEnabledSwitch.on = osc.isListening;
	self.sendHostTextField.text = osc.sendHost;
	self.sendPortTextField.text = [NSString stringWithFormat:@"%d", osc.sendPort];
	self.listenPortTextField.text = [NSString stringWithFormat:@"%d", osc.listenPort];
	self.listenGroupTextField.text = osc.listenGroup;
}

- (void)viewWillAppear:(BOOL)animated {
	self.localHostLabel.text = [WebServer wifiInterfaceAddress];
	[super viewWillAppear:animated];
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableOsc:(id)sender {
	if(self.oscEnabledSwitch.isOn) {
		[self startOsc:nil];
	}
	else {
		[osc stopListening];
	}
	[self.tableView reloadData];
}

- (IBAction)setSendHost:(id)sender {
	if([self.sendHostTextField.text isEqualToString:@""]) {
		self.sendHostTextField.text = @"localhost";
	}
	osc.sendHost = self.sendHostTextField.text;
}

- (IBAction)setSendPort:(id)sender {
	int port = [WebServer checkPortValueFromTextField:self.sendPortTextField];
	if(port < 0) { // set current port on bad value
		self.sendPortTextField.text = [NSString stringWithFormat:@"%d", osc.sendPort];
		return;
	}
	osc.sendPort = port;
}

- (IBAction)setListenPort:(id)sender {
	int port = [WebServer checkPortValueFromTextField:self.listenPortTextField];
	if(port < 0) { // set current port on bad value
		self.listenPortTextField.text = [NSString stringWithFormat:@"%d", osc.listenPort];
		return;
	}
	osc.listenPort = port;
	[self restart];
}

- (IBAction)setListenGroup:(id)sender {
	osc.listenGroup = self.listenGroupTextField.text;
	[self restart];
}

- (void)restart {
	[osc stopListening];
	
	// launch timer to make sure osc has enough time to disconnect
	[oscRestartTimer invalidate];
	oscRestartTimer = nil;
	oscRestartTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(startOsc:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:oscRestartTimer forMode:NSDefaultRunLoopMode];
}

- (void)startOsc:(NSTimer *)theTimer {
	if(![osc startListening]) {
		[[UIAlertController alertControllerWithTitle:@"Couldn't start OSC Server"
		                                     message:@"Check your port, host, & group settings."
		                           cancelButtonTitle:@"Ok"] show];
	}
	oscRestartTimer = nil;
}

#pragma mark UITableViewController

// hide sections based on osc status
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.oscEnabledSwitch.on ? 3 : 1;
}

@end
