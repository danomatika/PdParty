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

// get the full URL to the Documents directory
+ (NSString*)documentsPath;

#pragma mark Array Utils

+ (BOOL)isNumberIn:(NSArray*)array at:(int)index;
+ (BOOL)isStringIn:(NSArray*)array at:(int)index;

#pragma mark CGRect

+ (void)logRect:(CGRect)rect;

@end
