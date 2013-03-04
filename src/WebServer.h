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

// webdav server
@interface WebServer : NSObject 

+ (void)start:(NSString*)webFolder;
+ (void)stop;

@property (readonly, getter=isRunning) bool running;

@end
