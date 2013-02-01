/*
 * Dan Wilcox <danomatika.com>
 * Copyright (c) 2012 Robotcowboy Industries. All rights reserved.
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
