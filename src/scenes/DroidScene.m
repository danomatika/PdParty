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

#import "PureData.h"
#import "Gui.h"
#import "PdFile.h"

#import "Log.h"
#import "Util.h"

@implementation DroidScene

+ (id)sceneWithParent:(UIView*)parent andGui:(Gui*)gui {
	DroidScene *s = [[DroidScene alloc] init];
	s.parentView = parent;
	s.gui = gui;
	return s;
}

- (BOOL)scaleTouch:(UITouch*)touch forPos:(CGPoint*)pos {
	return NO;
}

#pragma mark Overridden Getters / Setters

- (SceneType)type {
	return SceneTypeDroid;
}

- (NSString *)typeString {
	return @"DroidScene";
}

#pragma mark Util

+ (BOOL)isDroidPartyDirectory:(NSString *)fullpath {
	return [[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"droidparty_main.pd"]];
}

@end
