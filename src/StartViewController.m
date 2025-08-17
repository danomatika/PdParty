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

@implementation StartViewController

- (void)awakeFromNib {

	// set so AppDelegate can pop view stack to beginning
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.startViewController = self;

	[super awakeFromNib];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set instance pointer
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	self.server = app.server;
	
	self.serverEnabledSwitch.on = self.server.isRunning;
	self.serverPortLabel.enabled = YES;
	self.serverPortTextField.text = [NSString stringWithFormat:@"%d", self.server.port];
	self.serverPortTextField.enabled = YES;

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
	                                         initWithImage:[UIImage imageNamed:@"info"]
	                                         style:UIBarButtonItemStylePlain
	                                         target:self
	                                         action:@selector(infoPressed:)];
}

- (void)dealloc {
	[self.server stop];
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.midi.delegate = nil;
	app.server.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.midi.delegate = self;
	app.server.delegate = self;
	if(app.osc.isListening) {
		self.oscLabel.text = app.osc.sendHost;
	}
	else {
		self.oscLabel.text = @"Disabled";
	}
	[self updateMidiLabel];
	self.navigationItem.rightBarButtonItem = [app nowPlayingButton];
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	app.midi.delegate = nil;
	app.server.delegate = nil;
	[super viewWillDisappear:animated];
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
			NSString *message = @"Wifi connection not found.\n\nServer will not be reachable unless device is plugged into computer.";
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Wifi?"
			                                                               message:message
			                                                     cancelButtonTitle:nil];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
				self.serverEnabledSwitch.on = NO; // reset switch
			}];
			UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Start Anyway"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
				[self startServer];
			}];
			[alert addAction:cancelAction];
			[alert addAction:doneAction];
			[alert show];
			return;
		}

		// wifi is good, start server
		[self startServer];
	}
	else {
		[self.server stop];
		self.serverPortLabel.enabled = YES;
		self.serverPortTextField.enabled = YES;
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

#pragma mark UI

- (void)infoPressed:(id)sender {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	NSURL *url = [NSURL fileURLWithPath:[Util.resourcePath stringByAppendingPathComponent:@"/about/about.html"]];
	[app launchWebViewForURL:url withTitle:@"About" sceneRotationsOnly:NO];
}

- (void)updateMidiLabel {
	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	if(app.midi.enabled) {
		self.midiLabel.text = [NSString stringWithFormat:@"In(%lu) Out(%lu)",
			(unsigned long)app.midi.inputs.count, (unsigned long)app.midi.outputs.count];
	}
	else {
		self.midiLabel.text = @"Disabled";
	}
}

- (void)updateServerInfo {
	// reloading the table view loads the footer text
	[self.tableView reloadData];
}

#pragma mark UITableViewController

// http://stackoverflow.com/questions/1547497/change-uitableview-section-header-footer-while-running-the-app?rq=1
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch(section) {
		case 1:
			if(self.server.isRunning) {
				NSString *hostNameUrl = self.server.hostNameUrl;
				NSString *bonjourUrl = self.server.bonjourUrl;
				if(hostNameUrl) {
					return [NSString stringWithFormat:@"Connect to %@\nor %@",
						self.server.hostUrl, hostNameUrl];
				}
				else if(bonjourUrl) {
					return [NSString stringWithFormat:@"Connect to %@\nor %@",
						self.server.hostUrl, bonjourUrl];
				}
				else {
					return [NSString stringWithFormat:@"Connect to %@",
						self.server.hostUrl];
				}
			}
			else {
				return @"Manage patches over WebDAV";
			}
			break;
		default:
			return nil;
	}
}

#pragma mark MidiBridgeDelegate

- (void)midiConnectionsChanged {
	[self updateMidiLabel];
}

#pragma mark WebServerDelegate

- (void)webServerDidStart {
	[self updateServerInfo];
}

- (void)webServerBonjourRegistered {
	[self updateServerInfo];
}

- (void)webServerDidStop {
	[self updateServerInfo];
}

#pragma mark Private

- (void)startServer {
	if(![self.server start]) {
		return;
	}
	self.serverPortLabel.enabled = NO;
	self.serverPortTextField.text = [NSString stringWithFormat:@"%d", self.server.port];
	self.serverPortTextField.enabled = NO;
}

@end
