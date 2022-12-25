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
#include "Scene.h"

@implementation Scene

+ (id)sceneWithParent:(UIView *)parent {
	Scene *s = [[Scene alloc] init];
	s.parentView = parent;
	return s;
}

- (id)init {
	self = [super init];
	if(self) {
		self.preferredOrientations = UIInterfaceOrientationMaskAll;
	}
	return self;
}

- (void)dealloc {
	[self close];
}

- (BOOL)open:(NSString *)path {
	return YES;
}

- (void)close {
	self.parentView = nil;
	self.gui = nil;
}

- (void)reshape {
}

// normalize to whole view
- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	return NO;
}

- (BOOL)requiresSensor:(SensorType)sensor {
	return NO;
}

- (BOOL)supportsSensor:(SensorType)sensor {
	return NO;
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return @"Scene";
}

- (BOOL)records {
	return NO;
}

- (BOOL)micControl {
	return NO;
}

- (BOOL)hasInfo {
	return NO;
}

- (NSString *)artist {
	return @"Unknown Artist";
}

- (NSString *)category {
	return @"None";
}

- (NSString *)description {
	return @"None";
}

- (NSString *)type {
	return @"EmptyScene";
}

- (int)sampleRate {
	return USER_SAMPLERATE;
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

- (BOOL)requiresPd {
	return YES;
}

- (BOOL)requiresAccelOrientation {
	return NO;
}

- (BOOL)requiresControls {
	return YES;
}

- (BOOL)requiresOnscreenControls {
	return NO;
}

- (int)contentHeight {
	return CGRectGetHeight(self.parentView.bounds);
}

- (BOOL)requiresViewport {
	return NO;
}

#pragma mark Util

- (void)addSearchPathsIn:(NSString *)directory {
	
	if(![NSFileManager.defaultManager fileExistsAtPath:directory]) {
		LogWarn(@"%@: search path %@ not found, skipping", self.type, directory);
		return;
	}
	LogVerbose(@"%@: adding search paths in %@", self.type, directory);

	NSError *error;
	NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:&error];
	if(!contents) {
		LogError(@"%@: couldn't read contents of path %@, error: %@", self.type, directory, error.localizedDescription);
		return;
	}
	
	LogVerbose(@"%@: found %lu paths", self.type, (unsigned long)contents.count);
	for(NSString *p in contents) {
		NSString *path = [directory stringByAppendingPathComponent:p];
		if([Util isDirectory:path]) {
			LogVerbose(@"%@: \tadded %@ to search path", self.type, p);
			[PdBase addToSearchPath:path];
		}
	}
}

+ (UIInterfaceOrientationMask)orientationMaskFromWidth:(float)width andHeight:(float)height {
	float aspect = width / height;
	if(aspect < 1.0) { // portrait
		return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
	}
	else if(aspect > 1.0) { // landscape
		return UIInterfaceOrientationMaskLandscape;
	}
	return UIInterfaceOrientationMaskAll;
}

@end
