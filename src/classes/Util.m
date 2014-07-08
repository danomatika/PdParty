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

+ (BOOL)isDeviceATablet {
	return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

+ (float)deviceOSVersion {
	return [[[UIDevice currentDevice] systemVersion] floatValue];
}

#pragma mark App

+ (CGFloat)appWidth {
    return [UIScreen mainScreen].applicationFrame.size.width;
}

+ (CGFloat)appHeight {
    return [UIScreen mainScreen].applicationFrame.size.height;
}

+ (CGSize)appSize {
    return CGSizeMake(
		[UIScreen mainScreen].applicationFrame.size.width,
		[UIScreen mainScreen].applicationFrame.size.height);
}

#pragma mark Logging Shortcuts

+ (void)logRect:(CGRect)rect {
	DDLogVerbose(@"%.2f %.2f %.2f %.2f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logRect:(CGRect)rect withHeader:(NSString *)header {
	DDLogVerbose(@"%@: %.2f %.2f %.2f %.2f", header, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logArray:(NSArray *)array {
	NSMutableString *arrayString = [[NSMutableString alloc] init];
	for(NSObject *object in array) {
		[arrayString appendFormat:@"%@ ", object.description];
	}
	DDLogVerbose(@"[ %@]", arrayString);
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

#pragma mark Conversion

// from:
// http://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text#2768081
+ (UIImage *)imageFromString:(NSString *)string withFont:(UIFont*)font {
	
    CGSize size  = [string sizeWithFont:font];
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    // draw in context, you can use also drawInRect:withFont:
    [string drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];

    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    

    return image;
}

+ (UIImage *)image:(UIImage *)image withTint:(UIColor *)tint {
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
	CGContextRef c = UIGraphicsGetCurrentContext();
	[image drawInRect:rect];
	CGContextSetFillColorWithColor(c, [tint CGColor]);
	CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
	CGContextFillRect(c, rect);
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

@end

#pragma mark Array Category

@implementation NSArray (EasyTypeCheckArray)

- (BOOL)isNumberAt:(int)index {
	return [[self objectAtIndex:index] isKindOfClass:[NSNumber class]];
}

- (BOOL)isStringAt:(int)index {
	return [[self objectAtIndex:index] isKindOfClass:[NSString class]];
}

@end

#pragma mark MutableString Category

@implementation NSMutableString (CharSetString)

- (void)setCharacter:(unichar)c atIndex:(unsigned)i {
	//NSLog(@"setting %c at %d in \"%@\"", c, i, self);
	[self replaceCharactersInRange:NSMakeRange(i, 1) withString:[NSString stringWithCharacters:&c length:1]];
}

@end

#pragma mark Image Category

@implementation UIImage (Overlay)

// from http://stackoverflow.com/questions/19274789/change-image-tintcolor-in-ios7
- (UIImage *)imageWithColor:(UIColor *)color {
	UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0, self.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	CGContextClipToMask(context, rect, self.CGImage);
	[color setFill];
	CGContextFillRect(context, rect);
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

@end
