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

#pragma mark Array Utils

+ (BOOL)isNumberIn:(NSArray*)array at:(int)index;
+ (BOOL)isStringIn:(NSArray*)array at:(int)index;
//+ (BOOL)isEqualIn:(NSArray*)array at:(int)index to:(NSString*)string;
//+ (BOOL)isEqualIn:(NSArray*)array at:(int)index to:(float)value;

//+ (float)asFloatIn:(NSArray*)array at:(int)index;
//+ (NSString*)asStringIn:(NSArray*)array at:(int)index;

#pragma mark CGRect

+ (void)logRect:(CGRect)rect;

@end
