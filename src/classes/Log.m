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

static TextViewLogger *s_textViewLogger = nil;

+ (void)setup {
	[DDLog addLogger:DDTTYLogger.sharedInstance];
	[DDLog addLogger:DDASLLogger.sharedInstance];
	if([NSUserDefaults.standardUserDefaults boolForKey:@"logTextView"]) {
		[Log enableTextViewLogger:YES];
	}
	switch(ddLogLevel) {
		case DDLogLevelInfo:
			DDLogInfo(@"Log level: INFO");
			break;
		case DDLogLevelVerbose:
			DDLogInfo(@"Log level: VERBOSE");
			break;
		default:
			DDLogInfo(@"Log level: %d", (int)ddLogLevel);
			break;
	}
}

#pragma mark TextViewLogger

+ (TextViewLogger *)textViewLogger {
	return s_textViewLogger;
}

+ (void)enableTextViewLogger:(BOOL)enable {
	if(!s_textViewLogger) {
		s_textViewLogger = [[TextViewLogger alloc] init];
		[DDLog addLogger:s_textViewLogger];
	}
	else {
		[DDLog removeLogger:s_textViewLogger];
		s_textViewLogger = nil;
	}
	[NSUserDefaults.standardUserDefaults setBool:enable forKey:@"logTextView"];
}

+ (BOOL)textViewLoggerEnabled {
	return (s_textViewLogger != nil);
}

@end
