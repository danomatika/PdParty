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
#import <CoreText/CoreText.h>

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

+ (NSString *)resourcePath {
	return [[NSBundle mainBundle] resourcePath];
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

+ (BOOL)copyContentsOfDirectory:(NSString *)srcDir toDirectory:(NSString *)destDir error:(NSError *)error {

	// create dest folder if it doesn't exist
	if(![[NSFileManager defaultManager] fileExistsAtPath:destDir isDirectory:nil]) {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:destDir withIntermediateDirectories:NO attributes:nil error:&error]) {
			DDLogError(@"Util: couldn't create %@, error: %@", destDir, error.localizedDescription);
			return NO;
		}
	}

	// copy all items within src into dest, this way we don't lose any other files or folders added by the user
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:srcDir error:&error];
	if(!contents) {
		return YES; // no contents to copy
	}
	for(NSString *p in contents) {
		NSString *srcPath = [srcDir stringByAppendingPathComponent:p];
		NSString *destPath = [destDir stringByAppendingPathComponent:p];
		BOOL isDir = NO;
		
		// remove existing files in the dest folder that match those in the src folder
		if([[NSFileManager defaultManager] fileExistsAtPath:destPath isDirectory:&isDir]) {
		
			// remove existing file
			if(!isDir && ![[NSFileManager defaultManager] removeItemAtPath:destPath error:&error]) {
				DDLogError(@"Util: couldn't remove %@, error: %@", destPath, error.localizedDescription);
				return NO;
			}
		}
		
		[[NSFileManager defaultManager] fileExistsAtPath:destPath isDirectory:&isDir];
		if(isDir) { // copy folder recursively
			[Util copyContentsOfDirectory:srcPath toDirectory:destPath error:error];
		}
		else { // copy file
			if(![[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:destPath error:&error]) {
				DDLogError(@"Util: couldn't copy %@ to %@, error: %@", srcPath, destPath, error.localizedDescription);
				return NO;
			}
		}
	}
	return YES;
}

+ (NSArray *)whichFilenames:(NSArray *)filenames existInDirectory:(NSString *)dir {
	if(![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:nil]) {
		DDLogError(@"Util: couldn't check if filenames exist, dir does not exist: %@", dir);
		return nil;
	}
	NSMutableArray *found = [NSMutableArray array];
	for(NSString *file in filenames) {
		NSString *filePath = [dir stringByAppendingPathComponent:file];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			[found addObject:file];
		}
	}
	return (found.count > 0) ? found : nil;
}

#pragma mark Images

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

#pragma mark Fonts

+ (NSString *)registerFont:(NSString *)fontPath {
	NSString *name = nil;
	NSData *inData = [NSData dataWithContentsOfFile:fontPath];
	CFErrorRef error;
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)inData);
	CGFontRef font = CGFontCreateWithDataProvider(provider);
	if(!CTFontManagerRegisterGraphicsFont(font, &error)) {
		CFStringRef errorDescription = CFErrorCopyDescription(error);
		DDLogError(@"Util: Failed to register font: %@", errorDescription);
		CFRelease(errorDescription);
	}
	else {
		name = CFBridgingRelease(CGFontCopyFullName(font));
	}
	CFRelease(font);
	CFRelease(provider);
	return name;
}

+ (void)unregisterFont:(NSString *)fontPath {
	NSURL *url = [[NSURL alloc] initFileURLWithPath:fontPath];
	CFErrorRef error;
	if(!CTFontManagerUnregisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, &error)) {
		CFStringRef errorDescription = CFErrorCopyDescription(error);
		DDLogError(@"Util: Failed to unregister font: %@", errorDescription);
		CFRelease(errorDescription);
	}
}

#pragma mark JSON

+ (id)parseJSONFromFile:(NSString *)path {
	NSError *error;
	id data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:0 error:&error];
	if(!data) {
		DDLogError(@"Util: parsing JSON from %@ failed: %@", path, error.debugDescription);
	}
	return data;
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
