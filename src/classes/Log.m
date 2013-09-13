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

#if DEBUG_PDPARTY
	int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
	int ddLogLevel = LOG_LEVEL_INFO;
#endif
