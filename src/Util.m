/*
 * Dan Wilcox <danomatika.com>
 * Copyright (c) 2012 Robotcowboy Industries. All rights reserved.
 */

#import "Util.h"

@implementation Util

+ (BOOL)isNumberIn:(NSArray*)array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSNumber class]];
}

+ (BOOL)isStringIn:(NSArray*)array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSString class]];
}

//+ (BOOL)isEqualIn:(NSArray*)array at:(int)index to:(NSString*)string {
//	return [[array objectAtIndex:index] isEqualToString:string]
//}

//+ (BOOL)isEqualIn:(NSArray*)array at:(int)index to:(float)value {
//	return ([[array objectAtIndex:index] floatValue] == value);
//}

//+ (float)asFloatIn:(NSArray*)array at:(int)index {
//	return [[array objectAtIndex:index] floatValue];
//}

//+ (NSString*)asStringIn:(NSArray*)array at:(int)index {
//	return [array objectAtIndex:index];
//}

+ (void)logRect:(CGRect)rect {
	NSLog(@"%.2f %.2f %.2f %.2f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

@end


