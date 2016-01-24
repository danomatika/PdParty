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

#import <Foundation/Foundation.h>

/// webdav server
@interface WebServer : NSObject 

@property (assign, nonatomic) int port; //< change only takes effect on server restart
@property (weak, readonly, nonatomic) NSString *hostName; //> Bonjour hostname
@property (assign,readonly, getter=isRunning, nonatomic) BOOL running;

/// start the server with the given dir as the server root
/// returns YES on success
- (BOOL)start:(NSString *)directory;
- (BOOL)start; //< start with the Documents folder as the root
- (void)stop;

/// is wifi enabled and the local network reachable?
+ (BOOL)isLocalWifiReachable;

/// get the ip address of the wifi interface
+ (NSString *)wifiInterfaceAddress;

/// returns port if texField value is valid, returns -1 & presents UIAlert if not
+ (int)checkPortValueFromTextField:(UITextField *)textField;

@end
