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

//#import <CoreFoundation/CoreFoundation.h>
#import "Reachability.h"

#import "Log.h"
#import "Util.h"

@interface WebServer ()
@property (strong) HTTPServer *server;
@end

@implementation WebServer

- (id)init {
	self = [super init];
    if(self) {
		self.server = [[HTTPServer alloc] init];
		[self.server setPort:8080]; // default
    }
    return self;
}

- (BOOL)start:(NSString*)webFolder {

	// create DAV server
	[self.server setConnectionClass:[DAVConnection class]];
	
	// enable Bonjour
	[self.server setType:@"_http._tcp."];

	// set document root
	[self.server setDocumentRoot:[webFolder stringByExpandingTildeInPath]];
	DDLogVerbose(@"HTTPServer: set root to %@", webFolder);

	// start DAV server
	NSError* error = nil;
	if(![self.server start:&error]) {
		DDLogError(@"HTTPServer: error starting: %@", error.localizedDescription);
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops"
															message:[NSString stringWithFormat:@"Coudln't start server: %@", error.localizedDescription]
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
	if(self.server.isRunning) {
		[self.server stop];
		DDLogVerbose(@"HTTPServer: stopped");
	}
}

#pragma mark Setter/Getter Overrides

- (void)setPort:(int)port {
	DDLogVerbose(@"HTTPServer: port set to %d", port);
	[self.server setPort:port];
}

- (int)port {
	if([self.server isRunning]) {
		return [self.server listeningPort];
	}
	else {
		return [self.server port];
	}
}

- (NSString*)hostName {
	if([self.server isRunning]) {
		return [self.server publishedName];
	}
	else {
		return [self.server name];
	}
}

- (BOOL)isRunning {
	return [self.server isRunning];
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

@end
