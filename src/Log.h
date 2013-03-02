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
#import "CocoaHTTPServer/Vendor/CocoaLumberjack/DDLog.h"
#import "CocoaHTTPServer/Vendor/CocoaLumberjack/DDTTYLogger.h"
#import "CocoaHTTPServer/Vendor/CocoaLumberjack/DDFileLogger.h"

// global log level
//
// from http://bluedogtech.blogspot.com/2010/12/global-log-level-control-with.html
//
// off, error, warn, info, verbose
//  0     1     3      7      15
extern int ddLogLevel;
