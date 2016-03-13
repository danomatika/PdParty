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
#import "WebServer.h"
 
#import "HTTPServer.h"
#import "DAVConnection.h"

#import <CFNetwork/CFNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "Reachability.h"

#import "Log.h"
#import "Util.h"

@interface WebServer () {
	HTTPServer *server;
}
@end

@implementation WebServer

- (id)init {
	self = [super init];
	if(self) {
		server = [[HTTPServer alloc] init];
		[server setPort:[[NSUserDefaults standardUserDefaults] integerForKey:@"webServerPort"]];
	}
	return self;
}

- (BOOL)start:(NSString *)directory {

	// create DAV server
	[server setConnectionClass:[DAVConnection class]];
	
	// enable Bonjour
	[server setType:@"_http._tcp."];

	// set document root
	[server setDocumentRoot:[directory stringByExpandingTildeInPath]];
	DDLogVerbose(@"WebServer: set root to %@", directory);

	// start DAV server
	NSError* error = nil;
	if(![server start:&error]) {
		DDLogError(@"WebServer: error starting: %@", error.localizedDescription);
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops"
															message:[NSString stringWithFormat:@"Couldn't start server: %@", error.localizedDescription]
														   delegate:self
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	return YES;
}

- (BOOL)start {
	return [self start:[Util documentsPath]];
}

- (void)stop {
	if(server.isRunning) {
		[server stop];
		DDLogVerbose(@"WebServer: stopped");
	}
}

#pragma mark Setter/Getter Overrides

- (void)setPort:(int)port {
	DDLogVerbose(@"WebServer: port set to %d", port);
	[server setPort:port];
	[[NSUserDefaults standardUserDefaults] setInteger:port forKey:@"webServerPort"];
}

- (int)port {
	if([server isRunning]) {
		return [server listeningPort];
	}
	else {
		return [server port];
	}
}

- (NSString *)hostName {
	if([server isRunning]) {
		return [server publishedName];
	}
	else {
		return [server name];
	}
}

- (BOOL)isRunning {
	return [server isRunning];
}

// from http://stackoverflow.com/questions/7975727/how-to-check-if-wifi-option-enabled-or-not
+ (BOOL)isLocalWifiReachable {
	Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
	[wifiReach startNotifier];
	
	NetworkStatus wifiStatus = [wifiReach currentReachabilityStatus];
	return (wifiStatus == NotReachable) ? NO : YES;
}

// from http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone
+ (NSString *)wifiInterfaceAddress {

	NSString *address = nil;
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;

	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if(success == 0) {

		// loop through interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL) {
			if(temp_addr->ifa_addr->sa_family == AF_INET) {
				NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];

				// iOS wifi interface = en0, include en1 for Mac wifi in simulator 
				if([interfaceName isEqualToString:@"en0"] || ([Util isDeviceRunningInSimulator] && [interfaceName isEqualToString:@"en1"])) {
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces);

	return address;
}

+ (int)checkPortValueFromTextField:(UITextField *)textField {
	// check given value
	// from http://stackoverflow.com/questions/6957203/ios-check-a-textfield-text
	int newPort = -1;
	if([[NSScanner scannerWithString:textField.text] scanInt:&newPort]) {
		if(newPort > 1024 || newPort == 0) { // ports 1024 and lower are reserved for the OS
			return newPort;
		}
	}
	
	// bad value
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid Port Number"
														message:@"Port number should be an integer greater than 1024. Set 0 to choose a random port."
													   delegate:self
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
	[alertView show];
	return -1;
}

@end
