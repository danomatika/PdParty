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

+ (id)sceneWithParent:(UIView*)parent {
	Scene *s = [[Scene alloc] init];
	s.parentView = parent;
	return s;
}

//- (id)init {
//	self = [super init];
//    if(self) {
//		self.parentView = nil;
//		self.gui = nil;
//    }
//    return self;
//}

- (void)dealloc {
	[self close];
}

- (BOOL)open:(NSString*)path {
	return YES;
}

- (void)close {
	self.parentView = nil;
	self.gui = nil;
}

- (void)reshape {
}

// normalize to whole view
- (BOOL)scaleTouch:(UITouch*)touch forPos:(CGPoint*)pos {
	return NO;
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return @"EmptyScene";
}

- (SceneType)type {
	return SceneTypeEmpty;
}

- (NSString *)typeString {
	return @"EmptyScene";
}

- (int)sampleRate {
	return PARTY_SAMPLERATE;
}

- (BOOL)requiresTouch {
	return NO;
}

- (BOOL)requiresAccel {
	return NO;
}

- (BOOL)requiresRotation {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

#pragma mark Util

- (void)addPatchLibSearchPaths {
	
	NSError *error;
	
	DDLogVerbose(@"%@: adding library patches to search path", self.typeString);
	
	NSString * libPatchesPath = [[Util bundlePath] stringByAppendingPathComponent:@"patches/lib"];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libPatchesPath error:&error];
	if(!contents) {
		DDLogError(@"%@: couldn't read files in path %@, error: %@", self.typeString, libPatchesPath, error.localizedDescription);
		return;
	}
	
	DDLogVerbose(@"%@: found %d paths in resources patches lib folder", self.typeString, contents.count);
	for(NSString *p in contents) {
		NSString *path = [libPatchesPath stringByAppendingPathComponent:p];
		if([Util isDirectory:path]) {
			DDLogVerbose(@"%@: \tadded %@ to search path", self.typeString, p);
			[PdBase addToSearchPath:path];
		}
	}
}

@end
