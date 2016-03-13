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
- (void) restart;

/// timer function to start the server after a gui change
- (void)startOsc:(NSTimer *)theTimer;

@end

@implementation OscViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set Osc pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	osc = app.osc;
	
	self.connectionEnabledSwitch.on = osc.isListening;
	self.hostTextField.text = osc.sendHost;
	self.outgoingPortTextField.text = [NSString stringWithFormat:@"%d", osc.sendPort];
	self.incomingPortTextField.text = [NSString stringWithFormat:@"%d", osc.listenPort];
}

- (void)viewWillAppear:(BOOL)animated {
	
	self.localHostLabel.text = [WebServer wifiInterfaceAddress];
	
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableOscConnection:(id)sender {
	if(self.connectionEnabledSwitch.isOn) {
		[self startOsc:nil];
	}
	else {
		[osc stopListening];
	}
	[self.tableView reloadData];
}

- (IBAction)setHost:(id)sender {
	osc.sendHost = self.hostTextField.text;
}

- (IBAction)setOutgoingPort:(id)sender {
	int port = [WebServer checkPortValueFromTextField:self.outgoingPortTextField];
	if(port < 0) { // set current port on bad value
		self.outgoingPortTextField.text = [NSString stringWithFormat:@"%d", osc.sendPort];
		return;
	}
	osc.sendPort = port;
}

- (IBAction)setIncomingPort:(id)sender {
	NSLog(@"setting incoming port");
	int port = [WebServer checkPortValueFromTextField:self.incomingPortTextField];
	if(port < 0) { // set current port on bad value
		self.incomingPortTextField.text = [NSString stringWithFormat:@"%d", osc.listenPort];
		return;
	}
	osc.listenPort = port;
	if(osc.isListening) {
		[self restart];
	}
}

- (void)restart {
	[osc stopListening];
	
	// launch timer to make sure osc has enough time to disconnect
	oscRestartTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(startOsc:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:oscRestartTimer forMode:NSDefaultRunLoopMode];
}

- (void)startOsc:(NSTimer *)theTimer {
	NSError *error;
	if(![osc startListening:error]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Couldn't start OSC Server"
									message:[NSString stringWithFormat:@"Check your port & address settings.\nError: %@", error]
								   delegate:self
						  cancelButtonTitle:@"Ok"
						  otherButtonTitles:nil];
		[alertView show];
	}
}

#pragma mark UITableViewController

// from http://code-ninja.org/blog/2012/02/29/ios-quick-tip-programmatically-hiding-sections-of-a-uitableview-with-static-cells/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0 && osc.isListening) {
		return 5;	// hide cells based on listening status
	}
	return 1;
}

@end
