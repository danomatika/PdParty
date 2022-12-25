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
#import "Log.h"

#import "TextViewLogger.h"

@implementation Log

static NSMutableArray *s_loggers = nil;
static TextViewLogger *s_textViewLogger = nil;

+ (void)setup {
	[Log addLogger:[ConsoleLogger new]];
	if([NSUserDefaults.standardUserDefaults boolForKey:@"logTextView"]) {
		[Log enableTextViewLogger:YES];
	}
	switch(logLevel) {
		case LogLevelInfo:
			LogInfo(@"Log level: INFO");
			break;
		case LogLevelVerbose:
			LogInfo(@"Log level: VERBOSE");
			break;
		default:
			LogInfo(@"Log level: %d", (int)logLevel);
			break;
	}
}

+ (void)log:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
	if(!format) {return;}
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	for(Logger *logger in s_loggers) {
		[logger logMessage:message];
	}
}

+ (void)addLogger:(Logger *)logger {
	if(!s_loggers) {s_loggers = [NSMutableArray new];}
	if(![s_loggers containsObject:logger]) {
		[s_loggers addObject:logger];
	}
}

+ (void)removeLogger:(Logger *)logger {
	[s_loggers removeObject:logger];
}

#pragma mark TextViewLogger

+ (TextViewLogger *)textViewLogger {
	return s_textViewLogger;
}

+ (void)enableTextViewLogger:(BOOL)enable {
	if(!s_textViewLogger) {
		s_textViewLogger = [[TextViewLogger alloc] init];
		[Log addLogger:s_textViewLogger];
	}
	else {
		[Log removeLogger:s_textViewLogger];
		s_textViewLogger = nil;
	}
	[NSUserDefaults.standardUserDefaults setBool:enable forKey:@"logTextView"];
}

+ (BOOL)textViewLoggerEnabled {
	return (s_textViewLogger != nil);
}

@end

#pragma mark - Logger

@implementation Logger
- (void)logMessage:(NSString *)message {}
@end

#pragma mark - ConsoleLogger

@implementation ConsoleLogger
- (void)logMessage:(NSString *)message {NSLog(@"%@", message);}
@end
