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


