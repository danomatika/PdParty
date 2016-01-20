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
	if([[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
		self.background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
		if(self.background.image) {
			self.background.contentMode = UIViewContentModeScaleAspectFill;
			[self.parentView addSubview:self.background];
		}
		else {
			DDLogError(@"DroidScene: couldn't load background image");
		}
	}
	
	// load font
	if(![self loadFont:[path stringByAppendingPathComponent:@"font.ttf"]]) {
		// try alternate name
		[self loadFont:[path stringByAppendingPathComponent:@"font-antialiased.ttf"]];
	}
	
	return ret;
}

- (void)close {
	if(self.background) {
		[self.background removeFromSuperview];
		self.background = nil;
	}
	if(self.fontPath) {
		[Util unregisterFont:self.fontPath];
		self.fontPath = nil;
	}
	[super close];
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

- (BOOL)requiresSensor:(SensorType)sensor {
	return NO;
}

- (BOOL)supportsSensor:(SensorType)sensor {
	switch(sensor) {
		case SensorTypeLocation: case SensorTypeCompass:
			return NO;
		default:
			return YES;
	}
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return [self.patch.pathName lastPathComponent];
}

- (NSString *)type {
	return @"DroidScene";
}

- (BOOL)requiresTouch {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

#pragma mark Util

+ (BOOL)isDroidPartyDirectory:(NSString *)fullpath {
	return [[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"droidparty_main.pd"]];
}

#pragma mark Private

- (BOOL)loadFont:(NSString *)fontPath {
	if([[NSFileManager defaultManager] fileExistsAtPath:fontPath]) {
		NSString *fontName = [Util registerFont:fontPath];
		if(fontName) {
			self.fontPath = fontPath;
			self.gui.fontName = fontName;
			return YES;
		}
		else {
			DDLogError(@"DroidScene: couldn't load font");
		}
	}
	return NO;
}

@end
