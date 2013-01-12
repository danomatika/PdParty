/*
 * Dan Wilcox <danomatika.com>
 * Copyright (c) 2012 Robotcowboy Industries. All rights reserved.
 */

#import "Lumberjack/DDLog.h"
#import "Lumberjack/DDTTYLogger.h"
#import "Lumberjack/DDFileLogger.h"

// global log level
//
// from http://bluedogtech.blogspot.com/2010/12/global-log-level-control-with.html
//
// off, error, warn, info, verbose
//  0     1     3      7      15
extern int ddLogLevel;
