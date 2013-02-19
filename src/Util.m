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

#import "Log.h"

@implementation Util

#pragma mark Paths

+ (NSString*)bundlePath {
	return [[NSBundle mainBundle] bundlePath];
}

+ (NSString*)documentsPath {
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [searchPaths objectAtIndex:0];
}

#pragma mark Array Utils

+ (BOOL)isNumberIn:(NSArray*)array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSNumber class]];
}

+ (BOOL)isStringIn:(NSArray*)array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSString class]];
}

#pragma mark CGRect

+ (void)logRect:(CGRect)rect {
	DDLogVerbose(@"%.2f %.2f %.2f %.2f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logData:(NSData*)data {
	unsigned char *bytes = (unsigned char*)[data bytes];
	NSMutableString *byteString = [[NSMutableString alloc] init];
	for(int i = 0; i < data.length; ++i) {
		[byteString appendFormat:@"%X ", bytes[i]];
	}
	DDLogVerbose(@"[ %@]", byteString);
}

@end


