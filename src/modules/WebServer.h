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
#pragma once

#import "GCDWebDAVServer.h"

/// webdav server event delegate
@protocol WebServerDelegate <NSObject>
- (void)webServerDidStart; ///< server has successfully started
- (void)webServerBonjourRegistered; ///< Bojour host ulr is registered
- (void)webServerDidStop; ///< server has shut down
@end

/// webdav server
@interface WebServer : NSObject <GCDWebDAVServerDelegate>

@property (assign, nonatomic) int port; ///< change only takes effect on server restart
@property (weak, readonly, nonatomic) NSString *hostUrl; ///< host url, nil if server not running
@property (weak, readonly, nonatomic) NSString *bonjourUrl; ///< Bonjour host url, nil if server not running
@property (assign, readonly, getter=isRunning, nonatomic) BOOL running;

/// called when server starts or stops
@property (assign, nonatomic) id<WebServerDelegate> delegate;

/// start the server with the given dir as the server root
/// returns YES on success
- (BOOL)start:(NSString *)directory;
- (BOOL)start; ///< start with the Documents folder as the root
- (void)stop; ///< stop the server

/// is wifi enabled and the local network reachable?
+ (BOOL)isLocalWifiReachable;

/// get the ip address of the wifi interface
+ (NSString *)wifiInterfaceAddress;

/// returns port if textField value is valid, returns -1 & presents UIAlert if not
+ (int)checkPortValueFromTextField:(UITextField *)textField;

@end
