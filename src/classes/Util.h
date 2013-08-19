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

#pragma mark Device

// are we running in the simulator?
+ (BOOL)isDeviceRunningInSimulator;

// is this device an ipad?
+ (BOOL)isDeviceATablet;

#pragma mark App

// application pixel dimensions, does not include status bar
+ (CGFloat) appWidth;
+ (CGFloat) appHeight;
+ (CGSize) appSize;

#pragma mark Conversion

// convert an orientation into degrees, relative to portrait
+ (int)orientationInDegrees:(UIInterfaceOrientation)orientation;

#pragma mark Logging Shortcuts

// print the pos & size of a CGRect
+ (void)logRect:(CGRect)rect;

// print an NSArray, uses object description strings
+ (void)logArray:(NSArray *)array;

// print NSData as raw hex bytes
+ (void)logData:(NSData *)data withHeader:(NSString *)header;

// print a UIColor as RGBA components
+ (void)logColor:(UIColor *)color;

#pragma mark Paths

// full path to the app bundle directory
+ (NSString *)bundlePath;

// full path to the Documents directory
+ (NSString *)documentsPath;

// returns YES if given path exists and is a directory
+ (BOOL)isDirectory:(NSString *)path;

@end

#pragma mark Array Category

@interface NSArray (EasyTypeCheckArray)

// check object type at array pos
- (BOOL)isNumberAt:(int)index;
- (BOOL)isStringAt:(int)index;

@end

#pragma mark String Category

@interface NSMutableString (CharSetString)

- (void)setCharacter:(unichar)c atIndex:(unsigned)i;

@end
