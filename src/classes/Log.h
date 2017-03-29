/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <CocoaLumberjack/CocoaLumberjack.h>

/// global log level
///
/// from http://bluedogtech.blogspot.com/2010/12/global-log-level-control-with.html
///
/// off, error, warn, info, verbose
///  0     1     3      7      15
extern DDLogLevel ddLogLevel;

@class TextViewLogger;

/// logging static methods
///
/// log using Lumberjack DDLog macros in place of NSLog:
///
/// DDLogError("an error ocurred");
/// DDLogWarn("something didn't happen right at %@", "some place");
/// DDLogInfo("1 + 1 = %d", 1+1);
/// DDLogVerbose("let me tell you the story of my life: %@", bioString);
///
@interface Log : NSObject

/// setup normal Lumberjack console logger, sets log level from NSUserDefaults if "logLevel" key exists
///
/// Note: log level is VERBOSE when building in debug mode for testing and DEBUG is defined
///
+ (void)setup;

#pragma Log Levels

/// set the current log level:
/// DDLogLevelOff, DDLogLevelError, DDLogLevelWarn, DDLohLevelInfo, DDLogLevelVerbose
/// updates the defaults "logLevel" value
+ (void)setLogLevel:(int)logLevel;

/// get the current log level
+ (int)logLevel;

/// get the default log level if the "logLevel" key exists in the current NSUserDefaults,
/// returns 0 if not found
+ (int)defaultLogLevel;

#pragma mark TextViewLogger

/// get global text view logger instance
+ (TextViewLogger *)textViewLogger;

/// enable the text view logger, updates the defaults "logTextView" value
+ (void)enableTextViewLogger:(BOOL)enable;

/// returns whether the text view logger is enabled or not
+ (BOOL)textViewLoggerEnabled;

@end
