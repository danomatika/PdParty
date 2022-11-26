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

#define CLAMP(val, min, max) MIN(MAX(val, min), max) ///< clamp between a min & max
#define RADIANS(degrees) ((degrees)*(M_PI/180)) ///< degrees to radians
#define DEGREES(radians) ((radians)*(180/M_PI)) ///< radians to degrees

/// utility static methods class
@interface Util : NSObject

#pragma mark Device

/// are we running in the simulator?
+ (BOOL)isDeviceRunningInSimulator;

/// is this device an iphone?
+ (BOOL)isDeviceAPhone;

/// is this device an ipad?
+ (BOOL)isDeviceATablet;

/// is this device an ipod touch?
+ (BOOL)isDeviceAnIpod;

/// get device iOS version as a float aka 6.1, 7.02, etc
+ (float)deviceOSVersion;

/// returns YES if the device supports Bluetooth Low Energy
+ (BOOL)deviceSupportsBluetoothLE;

#pragma mark App

/// application pixel dimensions, does not include status bar
+ (CGFloat) appWidth;
+ (CGFloat) appHeight;
+ (CGSize) appSize;

#pragma mark Logging Shortcuts

/// print the pos & size of a CGRect
+ (void)logRect:(CGRect)rect;

/// print CGRect prepended by header
+ (void)logRect:(CGRect)rect withHeader:(NSString *)header;

/// print an NSArray, uses object description strings
+ (void)logArray:(NSArray *)array;

/// print NSData as raw hex bytes
+ (void)logData:(NSData *)data withHeader:(NSString *)header;

/// print a UIColor as RGBA components
+ (void)logColor:(UIColor *)color;

#pragma mark Paths

/// full path to the app bundle directory
+ (NSString *)bundlePath;

/// full path to the Resources directory
+ (NSString *)resourcePath;

/// full path to the Documents directory
+ (NSString *)documentsPath;

/// returns YES if given path exists and is a directory
+ (BOOL)isDirectory:(NSString *)path;

/// recursively copy srcDir's contents to destDir, overwrites existing files
+ (BOOL)copyContentsOfDirectory:(NSString *)srcDir toDirectory:(NSString *)destDir error:(NSError *)error;

/// delete all items in dir, returns the number of deleted items
/// sets optional error and stops on failure
+ (NSUInteger)deleteContentsOfDirectory:(NSString *)dir error:(NSError *)error;

/// takes an array of filenames and returns those that exist in a given dir,
/// returns nil if none are found
+ (NSArray *)whichFilenames:(NSArray *)filenames existInDirectory:(NSString *)dir;

/// generate a copy file path similar to Finder's behavior when copying
///
/// 1. checks if the given path exists
/// 2. tries to create a copy path in the format "NAME #.EXT"
/// 3. if a file exists with that name, new names will be generated in the
///    format "NAME #.EXT" until an unused one is found
///
+ (NSString *)generateCopyPathForPath:(NSString *)path;


#pragma mark Images

/// renders a given string into a UIImage
+ (UIImage *)imageFromString:(NSString *)string withFont:(UIFont*)font;

/// returns a tinted copy of a given image
+ (UIImage *)image:(UIImage *)image withTint:(UIColor *)tint;

#pragma mark Fonts

/// register font file with the CoreText font manager,
/// returns font family name on success or nil on failure
+ (NSString *)registerFont:(NSString *)fontPath;

/// unregister font file with the CoreText font manager
+ (void)unregisterFont:(NSString *)fontPath;

#pragma mark JSON

/// parses JSON from a file into an NSDictionary or NSArray,
/// returns nil on error
+ (id)parseJSONFromFile:(NSString *)path;

@end

#pragma mark Array Category

@interface NSArray (EasyTypeCheckArray)

/// check if object is an NSNumber at array index
- (BOOL)isNumberAt:(int)index;

/// check if object is an NSString at array index
- (BOOL)isStringAt:(int)index;

@end

#pragma mark String Category

@interface NSMutableString (CharSetString)

/// sey a character as a specific index
- (void)setCharacter:(unichar)c atIndex:(unsigned)i;

@end

#pragma mark Image Category

@interface UIImage (OverlayColor)

/// returns a copy of the image tinted with a color
- (UIImage *)imageWithColor:(UIColor *)color;

@end

#pragma mark Alert Controller Category

@interface UIAlertController (AlertView)

/// creates an alert controller with an optional cancel button
+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 message:(NSString *)message
                       cancelButtonTitle:(NSString *)cancelButtonTitle;

/// present from the application's key window root view controller
- (void)show;

@end
