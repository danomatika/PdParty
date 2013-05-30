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
#import "PartyScene.h"

#import "Gui.h"

@implementation PartyScene

+ (id)sceneWithParent:(UIView*)parent andGui:(Gui*)gui {
	PartyScene *s = [[PartyScene alloc] init];
	s.parentView = parent;
	s.gui = gui;
	return s;
}

#pragma mark Overridden Getters / Setters

- (SceneType)type {
	return SceneTypeParty;
}

- (NSString *)typeString {
	return @"PartyScene";
}

#pragma mark Util

+ (BOOL)isPdPartyDirectory:(NSString *)fullpath {
	return [[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"_main.pd"]];
}

@end
