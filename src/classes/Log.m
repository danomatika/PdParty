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

#if DEBUG
	DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
	DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@implementation Log

static TextViewLogger *s_textViewLogger = nil;

+ (void)setup {
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"logLevel"]) {
		ddLogLevel = (DDLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:@"logLevel"];
	}
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"logTextView"]) {
		[Log enableTextViewLogger:YES];
	}
	DDLogInfo(@"Log level: %d", (int)ddLogLevel);
}

#pragma mark Log Levels

+ (void)setLogLevel:(int)logLevel {
	ddLogLevel = (DDLogLevel)logLevel;
	[[NSUserDefaults standardUserDefaults] setInteger:ddLogLevel forKey:@"logLevel"];
}

+ (int)logLevel {
	return (int)ddLogLevel;
}

+ (int)defaultLogLevel {
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"logLevel"]) {
		return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"logLevel"];
	}
	return (int)ddLogLevel;
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
	[[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"logTextView"];
}

+ (BOOL)textViewLoggerEnabled {
	return (s_textViewLogger != nil);
}

@end
