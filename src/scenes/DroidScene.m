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
#import "DroidScene.h"

#import "Canvas.h"
#import "SceneManager.h"

@implementation DroidScene

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui {
	DroidScene *s = [[DroidScene alloc] init];
	s.parentView = parent;
	s.gui = gui;
	return s;
}

- (BOOL)open:(NSString *)path {
	BOOL ret = [super open:[path stringByAppendingPathComponent:@"droidparty_main.pd"]];
	self.preferredOrientations = UIInterfaceOrientationMaskLandscape;
	
	// load background
	NSString *backgroundPath = [path stringByAppendingPathComponent:@"background.png"];
	if(![self loadBackground:backgroundPath]) {
		LogError(@"DroidScene: couldn't load background image");
	}
	
	// load font
	NSArray *fontPaths = [Util whichFilenames:@[@"font.ttf", @"font-antialiased.ttf"] existInDirectory:path];
	if(fontPaths) {
		if(![self loadFont:[path stringByAppendingPathComponent:fontPaths.firstObject]]) {
			LogError(@"DroidScene: couldn't load font");
		}
	}
	
	return ret;
}

- (void)close {
	[self clearBackground];
	[self clearFont];
	[super close];
}

- (void)reshape {
	[super reshape];
	if(self.background) {
		[self reshapeBackground];
	}
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

- (BOOL)requiresSensor:(SensorType)sensor {
	return NO;
}

- (BOOL)supportsSensor:(SensorType)sensor {
	switch(sensor) {
		case SensorTypeExtendedTouch: case SensorTypeLocation:
		case SensorTypeCompass: case SensorTypeMotion:
			return NO;
		default:
			return YES;
	}
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return self.patch.pathName.lastPathComponent;
}

- (NSString *)type {
	return @"DroidScene";
}

- (BOOL)requiresTouch {
	return NO;
}

- (BOOL)requiresControllers {
	return NO;
}

- (BOOL)requiresShake {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

#pragma mark Util

+ (BOOL)isDroidPartyDirectory:(NSString *)fullpath {
	return [NSFileManager.defaultManager fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"droidparty_main.pd"]];
}

@end
