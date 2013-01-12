/*
 * Dan Wilcox <danomatika.com>
 * Copyright (c) 2012 Robotcowboy Industries. All rights reserved.
 */

#import "Log.h"

#if DEBUG
	int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
	int ddLogLevel = LOG_LEVEL_INFO;
#endif