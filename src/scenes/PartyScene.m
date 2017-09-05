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

@interface PartyScene () {
	NSDictionary *info;
}
@end

@implementation PartyScene

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui {
	PartyScene *s = [[PartyScene alloc] init];
	s.parentView = parent;
	s.gui = gui;
	return s;
}

- (BOOL)open:(NSString *)path {
	if([super open:[path stringByAppendingPathComponent:@"_main.pd"]]) {
	
		// load info
		info = [PartyScene infoForSceneAt:path];
		if(info) {
			DDLogInfo(@"PartyScene: loaded info");
		}

		return YES;
	}
	return NO;
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	if(self.hasInfo) {
		NSString *n = [info objectForKey:@"name"];
		if(n) {
			return n;
		}
	}
	return [self.patch.pathName lastPathComponent];
}

- (BOOL)hasInfo {
	return (info != nil);
}

- (NSString *)artist {
	if(self.hasInfo) {
		NSString *a = [info objectForKey:@"author"];
		if(a) {
			return a;
		}
	}
	return [super artist];
}

- (NSString *)category {
	if(self.hasInfo) {
		NSString *c = [info objectForKey:@"category"];
		if(c) {
			return c;
		}
	}
	return [super category];
}

- (NSString *)description {
	if(self.hasInfo) {
		NSString *d = [info objectForKey:@"description"];
		if (d) {
			return d;
		}
	}
	return [super description];
}

- (NSString *)type {
	return @"PartyScene";
}

#pragma mark Util

+ (BOOL)isPdPartyDirectory:(NSString *)fullpath {
	return [[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"_main.pd"]];
}

+ (UIImage*)thumbnailForSceneAt:(NSString *)fullpath {
	NSArray *imagePaths = [Util whichFilenames:@[@"thumb.png", @"Thumb.png", @"thumb.jpg", @"Thumb.jpg"] existInDirectory:fullpath];
	if(imagePaths) {
		return [[UIImage alloc] initWithContentsOfFile:[fullpath stringByAppendingPathComponent:[imagePaths firstObject]]];
	}
	return nil;
}

+ (NSDictionary*)infoForSceneAt:(NSString *)fullpath {
	NSArray *infoPaths = [Util whichFilenames:@[@"info.json", @"Info.json"] existInDirectory:fullpath];
	if(infoPaths) {
		return [Util parseJSONFromFile:[fullpath stringByAppendingPathComponent:[infoPaths firstObject]]];
	}
	return nil;
}

@end
