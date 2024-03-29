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
#import <CoreLocation/CoreLocation.h>

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

+ (BOOL)isDeviceAPhone {
	return [UIDevice.currentDevice.model isEqualToString:@"iPhone"];
}

+ (BOOL)isDeviceATablet {
	return (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

+ (BOOL)isDeviceAnIpod {
	return [UIDevice.currentDevice.model isEqualToString:@"iPod touch"];
}

+ (float)deviceOSVersion {
	return UIDevice.currentDevice.systemVersion.floatValue;
}

+ (BOOL)deviceSupportsBluetoothLE {
#if TARGET_IPHONE_SIMULATOR
	return YES;
#else
	return [CLLocationManager isMonitoringAvailableForClass:CLBeaconRegion.class];
#endif
}

#pragma mark App

+ (CGFloat)appWidth {
	return UIScreen.mainScreen.bounds.size.width;
}

+ (CGFloat)appHeight {
	return UIScreen.mainScreen.bounds.size.height;
}

+ (CGSize)appSize {
	return CGSizeMake(
		UIScreen.mainScreen.bounds.size.width,
		UIScreen.mainScreen.bounds.size.height);
}

#pragma mark Logging Shortcuts

+ (void)logRect:(CGRect)rect {
	LogVerbose(@"%.2f %.2f %.2f %.2f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logRect:(CGRect)rect withHeader:(NSString *)header {
	LogVerbose(@"%@: %.2f %.2f %.2f %.2f", header, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void)logArray:(NSArray *)array {
	NSMutableString *arrayString = [NSMutableString string];
	for(NSObject *object in array) {
		[arrayString appendFormat:@"%@ ", object.description];
	}
	LogVerbose(@"[ %@]", arrayString);
}

+ (void)logData:(NSData *)data withHeader:(NSString *)header {
	unsigned char *bytes = (unsigned char*)[data bytes];
	NSMutableString *byteString = [NSMutableString string];
	for(int i = 0; i < data.length; ++i) {
		[byteString appendFormat:@"%02X ", bytes[i]];
	}
	LogVerbose(@"%@[ %@]", header, byteString);
}

+ (void)logColor:(UIColor *)color {
	CGFloat r, g, b, a;
	if([color getRed:&r green:&g blue:&b alpha:&a]) {
		LogVerbose(@"%f %f %f %f", r, g, b, a);
	}
}

#pragma mark Paths

+ (NSString *)bundlePath {
	return NSBundle.mainBundle.bundlePath;
}

+ (NSString *)resourcePath {
	return NSBundle.mainBundle.resourcePath;
}

+ (NSString *)documentsPath {
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return searchPaths.firstObject;
}

+ (BOOL)isDirectory:(NSString *)path {
	BOOL isDir = NO;
	[NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir];
	return isDir;
}

+ (BOOL)copyContentsOfDirectory:(NSString *)srcDir toDirectory:(NSString *)destDir error:(NSError *)error {

	// create dest folder if it doesn't exist
	if(![NSFileManager.defaultManager fileExistsAtPath:destDir isDirectory:nil]) {
		if(![NSFileManager.defaultManager createDirectoryAtPath:destDir withIntermediateDirectories:NO attributes:nil error:&error]) {
			LogError(@"Util: couldn't create %@, error: %@", destDir, error.localizedDescription);
			return NO;
		}
	}

	// copy all items within src into dest, this way we don't lose any other files or folders added by the user
	NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:srcDir error:&error];
	if(!contents) {
		return YES; // no contents to copy
	}
	for(NSString *p in contents) {
		NSString *srcPath = [srcDir stringByAppendingPathComponent:p];
		NSString *destPath = [destDir stringByAppendingPathComponent:p];
		BOOL isDir = NO;
		
		// remove existing files in the dest folder that match those in the src folder
		if([NSFileManager.defaultManager fileExistsAtPath:destPath isDirectory:&isDir]) {
		
			// remove existing file
			if(!isDir && ![NSFileManager.defaultManager removeItemAtPath:destPath error:&error]) {
				LogError(@"Util: couldn't remove %@, error: %@", destPath, error.localizedDescription);
				return NO;
			}
		}
		
		[NSFileManager.defaultManager fileExistsAtPath:destPath isDirectory:&isDir];
		if(isDir) { // copy folder recursively
			[Util copyContentsOfDirectory:srcPath toDirectory:destPath error:error];
		}
		else { // copy file
			if(![NSFileManager.defaultManager copyItemAtPath:srcPath toPath:destPath error:&error]) {
				LogError(@"Util: couldn't copy %@ to %@, error: %@", srcPath, destPath, error.localizedDescription);
				return NO;
			}
		}
	}
	return YES;
}

+ (NSUInteger)deleteContentsOfDirectory:(NSString *)dir error:(NSError *)error {
	NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:&error];
	if(!contents) {
		return YES; // no contents to copy
	}
	NSUInteger count = 0;
	for(NSString *p in contents) {
		NSString *path = [dir stringByAppendingPathComponent:p];
		if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
			LogError(@"Util: couldn't delete %@, error: %@", path, error.localizedDescription);
			return count;
		}
		count++;
	}
	return count;
}

+ (NSArray *)whichFilenames:(NSArray *)filenames existInDirectory:(NSString *)dir {
	if(![NSFileManager.defaultManager fileExistsAtPath:dir isDirectory:nil]) {
		LogError(@"Util: couldn't check if filenames exist, dir does not exist: %@", dir);
		return nil;
	}
	NSMutableArray *found = [NSMutableArray array];
	for(NSString *file in filenames) {
		NSString *filePath = [dir stringByAppendingPathComponent:file];
		if([NSFileManager.defaultManager fileExistsAtPath:filePath]) {
			[found addObject:file];
		}
	}
	return (found.count > 0) ? found : nil;
}

+ (NSString *)generateCopyPathForPath:(NSString *)path {
	int tries = 0;
	NSString *copy = path;
	NSString *name = path.lastPathComponent.stringByDeletingPathExtension;
	NSString *ext = path.lastPathComponent.pathExtension;
	while([NSFileManager.defaultManager fileExistsAtPath:copy]) {
		NSString *newFilename = [NSString stringWithFormat:@"%@%@%@", name,
		                         (tries > 0 ? [NSString stringWithFormat:@" %d", tries] : @""),
		                         ([ext isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", ext])];
		copy = [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:newFilename];
		tries++;
	}
	return copy;
}


#pragma mark Images

// from:
// http://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text#2768081
+ (UIImage *)imageFromString:(NSString *)string withFont:(UIFont*)font {
	
	CGSize size = [string sizeWithAttributes:@{NSFontAttributeName:font}];
	size.width = ceil(size.width);
	size.height = ceil(size.height);
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

	// draw in context, you can use also drawInRect:withFont:
	[string drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:@{NSFontAttributeName:font}];

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
	CGContextSetFillColorWithColor(c, tint.CGColor);
	CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
	CGContextFillRect(c, rect);
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

#pragma mark Fonts

/// try loading first as registration fails if the font is already available
+ (NSString *)registerFont:(NSString *)fontPath {
	NSString *name = nil;
	NSData *inData = [NSData dataWithContentsOfFile:fontPath];
	if(!inData) {return nil;}
	CFErrorRef error;
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)inData);
	CGFontRef font = CGFontCreateWithDataProvider(provider);
	if(font) {
		name = CFBridgingRelease(CGFontCopyFullName(font));
		if([UIFont fontWithName:name size:10]) {
			// loaded, so must be registered
		}
		else if(!CTFontManagerRegisterGraphicsFont(font, &error)) {
			CFStringRef errorDescription = CFErrorCopyDescription(error);
			LogError(@"Util: Failed to register font: %@", errorDescription);
			CFRelease(errorDescription);
			name = nil;
		}
	}
	CFRelease(font);
	CFRelease(provider);
	return name;
}

// quiet errors for now
+ (void)unregisterFont:(NSString *)fontPath {
	NSURL *url = [[NSURL alloc] initFileURLWithPath:fontPath];
	CFErrorRef error;
	if(!CTFontManagerUnregisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, &error)) {
		//CFStringRef errorDescription = CFErrorCopyDescription(error);
		//LogError(@"Util: Failed to unregister font: %@", errorDescription);
		//CFRelease(errorDescription);
	}
}

#pragma mark JSON

+ (id)parseJSONFromFile:(NSString *)path {
	NSError *error;
	id data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:0 error:&error];
	if(!data) {
		LogError(@"Util: parsing JSON from %@ failed: %@", path, error.debugDescription);
	}
	return data;
}

@end

#pragma mark Array Category

@implementation NSArray (EasyTypeCheckArray)

- (BOOL)isNumberAt:(int)index {
	return [[self objectAtIndex:index] isKindOfClass:NSNumber.class];
}

- (BOOL)isStringAt:(int)index {
	return [[self objectAtIndex:index] isKindOfClass:NSString.class];
}

@end

#pragma mark MutableString Category

@implementation NSMutableString (CharSetString)

- (void)setCharacter:(unichar)c atIndex:(unsigned)i {
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

#pragma mark Alert Controller Category

@implementation UIAlertController (AlertView)

+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 message:(NSString *)message
                       cancelButtonTitle:(NSString *)cancelButtonTitle {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
	                                                               message:message
	                                                        preferredStyle:UIAlertControllerStyleAlert];
	if(cancelButtonTitle) {
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle
		                                                       style:UIAlertActionStyleCancel
		                                                     handler:nil];
		[alert addAction:cancelAction];
	}
	return alert;
}

- (void)show {
	UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
	while(root.presentedViewController) {
		root = root.presentedViewController;
	}
	[root presentViewController:self animated:YES completion:nil];
}

@end
