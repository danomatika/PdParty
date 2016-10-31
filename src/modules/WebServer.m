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

//#import <CFNetwork/CFNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <net/if.h>

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
	Reachability *wifiReach = [Reachability reachabilityForInternetConnection];
	return [wifiReach currentReachabilityStatus] == ReachableViaWiFi;
}

// from http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone
+ (NSString *)wifiInterfaceAddress {
	return [WebServer getIPAddressPreferIPv4:YES withCellular:NO withSimulator:[Util isDeviceRunningInSimulator]];
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

#pragma mark Private

// find current IP address from connected interfaces (IPv4 and IPv6)
// from http://stackoverflow.com/a/10803584/2146055

+ (NSString *)getIPAddressPreferIPv4:(BOOL)preferIPv4 withCellular:(BOOL)cellular withSimulator:(BOOL)simulator {
	NSMutableArray *searchArray = [NSMutableArray new];
	if(preferIPv4) {
		[searchArray addObjectsFromArray:@[ @"en0/ipv4", @"en0/ipv6" ]];
		if(cellular) {
			[searchArray addObjectsFromArray:@[ @"pdp_ip0/ipv4", @"pdp_ip0/ipv6" ]];
		}
		if(simulator) {
			[searchArray addObjectsFromArray:@[ @"en1/ipv4", @"en1/ipv6" ]];
		}
	}
	else {
		[searchArray addObjectsFromArray:@[ @"en0/ipv6", @"en0/ipv4" ]];
		if(cellular) {
			[searchArray addObjectsFromArray:@[ @"pdp_ip0/ipv6", @"pdp_ip0/ipv4" ]];
		}
		if(simulator) {
			[searchArray addObjectsFromArray:@[ @"en1/ipv6", @"en1/ipv4" ]];
		}
	}
	NSDictionary *addresses = [WebServer getIPAddresses];
	__block NSString *address;
	[searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
		address = addresses[key];
		if(address) {
			*stop = YES;
		}
	} ];
	return address ? address : @"0.0.0.0";
}
+ (NSDictionary *)getIPAddresses {
	NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
	// retrieve the current interfaces - returns 0 on success
	struct ifaddrs *interfaces;
	if(!getifaddrs(&interfaces)) {
		// loop through linked list of interfaces
		struct ifaddrs *interface;
		for(interface=interfaces; interface; interface=interface->ifa_next) {
			if(!(interface->ifa_flags & IFF_UP)) {
				continue; // deeply nested code harder to read
			}
			const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
			char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
			if(addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
				NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
				NSString *type;
				if(addr->sin_family == AF_INET) {
					if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
						type = @"ipv4";
					}
				}
				else {
					const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
					if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
						type = @"ipv6";
					}
				}
				if(type) {
					NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
					addresses[key] = [NSString stringWithUTF8String:addrBuf];
				}
			}
		}
		// free memory
		freeifaddrs(interfaces);
	}
	return [addresses count] ? addresses : nil;
}

@end
