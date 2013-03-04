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

#import "Log.h"

static HTTPServer *server;

@implementation WebServer

+ (void)start:(NSString*)webFolder {

	// configure logging system
	[DDLog addLogger:[DDTTYLogger sharedInstance]];

	// create DAV server
	server = (HTTPServer*) [[HTTPServer alloc] init];
	[server setConnectionClass:[DAVConnection class]];
	[server setPort:8080];

	// enable Bonjour
	[server setType:@"_http._tcp."];

	// set document root
	[server setDocumentRoot:[webFolder stringByExpandingTildeInPath]];
	DDLogVerbose(@"WebServer: set root to %@", webFolder);

	// start DAV server
	NSError* error = nil;
	if(![server start:&error]) {
		DDLogError(@"WebServer: error starting server: %@", [error localizedDescription]);
	}
	DDLogVerbose(@"WebServer: started server, port: %d", [server port]);
}

+ (void)stop {
	if(server) {
		[server stop];
	}
	server = nil;
}

+ (bool)running {
	if(server) {
		return [server isRunning];
	}
	return false;
}


@end
