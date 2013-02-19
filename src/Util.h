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
#import <Foundation/Foundation.h>

@interface Util : NSObject

#pragma mark Paths

// full path to the app bundle directory
+ (NSString*)bundlePath;

// full path to the Documents directory
+ (NSString*)documentsPath;

#pragma mark Array Utils

// check object type at array pos
+ (BOOL)isNumberIn:(NSArray*)array at:(int)index;
+ (BOOL)isStringIn:(NSArray*)array at:(int)index;

#pragma mark Logging Shortcuts

// print the pos & size of a CGRect
+ (void)logRect:(CGRect)rect;

// print NSData as raw hex bytes
+ (void)logData:(NSData*)data withHeader:(NSString*)header;

@end
