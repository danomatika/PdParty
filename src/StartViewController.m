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
#import "StartViewController.h"

#import "WebServer.h"
#import "AppDelegate.h"

@interface StartViewController () {
	NSTimer *serverInfoTimer;
}

/// timer function to update the server footer info
- (void)updateServerInfo:(NSTimer *)theTimer;

@end

@implementation StartViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if(!self.server) {
		self.server = [[WebServer alloc] init];
	}
	self.serverEnabledSwitch.on = self.server.isRunning;
	
	self.serverPortLabel.enabled = YES;
	self.serverPortTextField.text = [NSString stringWithFormat:@"%d", self.server.port];
	self.serverPortTextField.enabled = YES;
	
	if([Util deviceOSVersion] >= 7.0) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
		                                         initWithImage:[UIImage imageNamed:@"info"]
		                                         style:UIBarButtonItemStylePlain
		                                         target:self
		                                         action:@selector(infoPressed:)];
	}
	else { // light button on iOS 6
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
		                                         initWithImage:[Util image:[UIImage imageNamed:@"info"] withTint:[UIColor whiteColor]]
		                                         style:UIBarButtonItemStylePlain
		                                         target:self
		                                         action:@selector(infoPressed:)];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if(app.osc.isListening) {
		self.oscLabel.text = [NSString stringWithFormat:@"OSC: %@", app.osc.sendHost];
	}
	else {
		self.oscLabel.text = @"OSC: Disabled";
	}
	if(app.midi.isEnabled) {
		self.midiLabel.text = [NSString stringWithFormat:@"MIDI: In(%u) Out(%u)",
			app.midi.inputs.count, app.midi.outputs.count];
	}
	else {
		self.midiLabel.text = @"MIDI: Disabled";
	}
	self.navigationItem.rightBarButtonItem = [app nowPlayingButton];
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self.server stop];
	[self setServerPortLabel:nil];
	[super viewDidUnload];
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableWebServer:(id)sender {
	if(self.serverEnabledSwitch.isOn) {
	
		// check if wifi is on/reachable
		if(![WebServer isLocalWifiReachable]) {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Wifi?"
			                                                    message:@"You need a Wifi connection in order to enable the server"
			                                                   delegate:self
			                                          cancelButtonTitle:@"Ok"
			                                          otherButtonTitles:nil];
			[alertView show];
			self.serverEnabledSwitch.on = NO; // reset switch
			return;
		}
	
		// wifi is good, start server
		if(![self.server start]) {
			return;
		}
		self.serverPortLabel.enabled = NO;
		self.serverPortTextField.text = [NSString stringWithFormat:@"%d", self.server.port];
		self.serverPortTextField.enabled = NO;
		
		// launch timer to make sure server has enough time to setup before getting the host info for the footer text
		serverInfoTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateServerInfo:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:serverInfoTimer forMode:NSDefaultRunLoopMode];
	}
	else {
		[self.server stop];
		self.serverPortLabel.enabled = YES;
		self.serverPortTextField.enabled = YES;
		[self.tableView reloadData]; // reset footer text
	}
}

- (IBAction)setWebServerPort:(id)sender {
	int port = [WebServer checkPortValueFromTextField:self.serverPortTextField];
	if(port < 0) { // set current port on bad value
		self.serverPortTextField.text = [NSString stringWithFormat:@"%d", self.server.port];
		return;
	}
	self.server.port = port;
}

- (void)updateServerInfo:(NSTimer *)theTimer {
	// reloading the table view loads the footer text
	[self.tableView reloadData];
}

#pragma mark UI

- (void)infoPressed:(id)sender {
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	NSURL *url = [NSURL fileURLWithPath:[[Util resourcePath] stringByAppendingPathComponent:@"/about/about.html"]];
	[app launchWebViewForURL:url withTitle:@"About"];
}

#pragma mark UITableViewController

// http://stackoverflow.com/questions/1547497/change-uitableview-section-header-footer-while-running-the-app?rq=1
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch(section) {
		case 1:
			if(self.server.isRunning) {
				return [NSString stringWithFormat:@"Connect to http://%@.local:%d\n  or http://%@:%d",
					self.server.hostName, self.server.port, [WebServer wifiInterfaceAddress], self.server.port];
			}
			else {
				return @"Manage patches over WebDAV";
			}
			break;
		default:
			return nil;
	}
}

@end
