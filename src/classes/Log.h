/*
 * Copyright (c) 2015,2022 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * The low-level NSLog wrapping is taken from CocoaLumberjack:
 * https://github.com/CocoaLumberjack/CocoaLumberjack
 */

// log levels
typedef NS_OPTIONS(NSUInteger, LogFlag) {
    LogFlagError   = (1 << 0), // 00001
    LogFlagWarning = (1 << 1), // 00010
    LogFlagInfo    = (1 << 2), // 00100
    LogFlagDebug   = (1 << 3), // 01000
    LogFlagVerbose = (1 << 4)  // 10000
};

/// bit mask flags for filtering log levels
typedef NS_ENUM(NSUInteger, LogLevel) {
    LogLevelOff     = 0,
    LogLevelError   = (LogFlagError),
    LogLevelWarning = (LogLevelError   | LogFlagWarning),
    LogLevelInfo    = (LogLevelWarning | LogFlagInfo),
    LogLevelDebug   = (LogLevelInfo    | LogFlagDebug),
    LogLevelVerbose = (LogLevelDebug   | LogFlagVerbose),
    LogLevelAll     = NSUIntegerMax
};

/// global log level
///
/// from http://bluedogtech.blogspot.com/2010/12/global-log-level-control-with.html
///
#if DEBUG
	static const LogLevel logLevel = LogLevelVerbose;
#else
	static const LogLevel logLevel = LogLevelInfo;
#endif

// log method
#define LOG_MACRO(format, ...) [Log log:format, ##__VA_ARGS__]

// current log level variable
#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF logLevel
#endif

// log message filtering
// if level is a constant, the compiler can optimize out the entire macro call
#define LOG_MAYBE(level, flag, format, ...) \
        do { if((level & flag) != 0) LOG_MACRO(format, ##__VA_ARGS__); } while(0)

// NSLog replacements
#define DDLogError(format, ...)   LOG_MAYBE(LOG_LEVEL_DEF, LogFlagError,   format, ##__VA_ARGS__)
#define DDLogWarn(format, ...)    LOG_MAYBE(LOG_LEVEL_DEF, LogFlagWarning, format, ##__VA_ARGS__)
#define DDLogInfo(format, ...)    LOG_MAYBE(LOG_LEVEL_DEF, LogFlagInfo,    format, ##__VA_ARGS__)
#define DDLogDebug(format, ...)   LOG_MAYBE(LOG_LEVEL_DEF, LogFlagDebug,   format, ##__VA_ARGS__)
#define DDLogVerbose(format, ...) LOG_MAYBE(LOG_LEVEL_DEF, LogFlagVerbose, format, ##__VA_ARGS__)

#pragma mark - Log

@class Logger;
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

/// set up console logger
/// note: log level is VERBOSE when building in debug mode for testing and DEBUG
///       is defined
+ (void)setup;

/// log a message
+ (void)log:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/// add a logger
+ (void)addLogger:(Logger *)logger;

/// remove a logger
+ (void)removeLogger:(Logger *)logger;

#pragma mark TextViewLogger

/// get global text view logger instance
+ (TextViewLogger *)textViewLogger;

/// enable the text view logger, updates the defaults "logTextView" value
+ (void)enableTextViewLogger:(BOOL)enable;

/// returns whether the text view logger is enabled or not
+ (BOOL)textViewLoggerEnabled;

@end

#pragma mark - Logger

/// base logging class
@interface Logger : NSObject

/// handle a new message to log, default implementation does nothing
- (void)logMessage:(NSString *)message;

@end

#pragma mark - ConsoleLogger

/// text console logger
@interface ConsoleLogger : Logger
@end
