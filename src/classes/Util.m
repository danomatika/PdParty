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

+ (NSString *)bundlePath {
	return [[NSBundle mainBundle] bundlePath];
}

+ (NSString *)documentsPath {
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [searchPaths objectAtIndex:0];
}

+ (BOOL)isDirectory:(NSString *)path {
	BOOL isDir = NO;
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return isDir;
}

#pragma mark Device

// from http://stackoverflow.com/questions/458304/how-can-i-programmatically-determine-if-my-app-is-running-in-the-iphone-simulato
+ (BOOL)isDeviceRunningInSimulator; {
	#if TARGET_IPHONE_SIMULATOR
		return YES;
	#elif TARGET_OS_IPHONE
		return NO;
	#else // unknown
		return NO;
	#endif
}

+ (BOOL)isDeviceATablet; {
	return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

#pragma mark Array

+ (BOOL)isNumberIn:(NSArray *)array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSNumber class]];
}

+ (BOOL)isStringIn:(NSArray* )array at:(int)index {
	return [[array objectAtIndex:index] isKindOfClass:[NSString class]];
}

#pragma mark CGRect

+ (void)logRect:(CGRect)rect {
	DDLogVerbose(@"%.2f %.2f %.2f %.2f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logData:(NSData *)data withHeader:(NSString *)header {
	unsigned char *bytes = (unsigned char*)[data bytes];
	NSMutableString *byteString = [[NSMutableString alloc] init];
	for(int i = 0; i < data.length; ++i) {
		[byteString appendFormat:@"%02X ", bytes[i]];
	}
	DDLogVerbose(@"%@[ %@]", header, byteString);
}

+ (void)logColor:(UIColor *)color {
	CGFloat r, g, b, a;
	if([color getRed:&r green:&g blue:&b alpha:&a]) {
		DDLogVerbose(@"%f %f %f %f", r, g, b, a);
	}
}

@end

#pragma mark MutableString

@implementation NSMutableString (StringUtils)

- (void)setCharacter:(unichar)c atIndex:(unsigned)i {
	NSLog(@"setting %c at %d in \"%@\"", c, i, self);
	[self replaceCharactersInRange:NSMakeRange(i, 1) withString:[NSString stringWithCharacters:&c length:1]];
}
@end
