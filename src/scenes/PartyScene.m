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

		// load background
		NSArray *backgroundPaths = [Util whichFilenames:@[@"background.png", @"background.jpg"] existInDirectory:path];
		for(NSString *backgroundPath in backgroundPaths) {
			if([self loadBackground:[path stringByAppendingPathComponent:backgroundPath]]) {break;}
			LogError(@"PartyScene: couldn't load %@", backgroundPath);
		}

		// load info
		info = [PartyScene infoForSceneAt:path];
		if(info) {
			LogInfo(@"PartyScene: loaded info");
		}

		return YES;
	}
	return NO;
}

- (void)close {
	// disconnect ViewPort cnv
	if(self.requiresViewport) {
		for(Widget *w in self.gui.widgets) {
			if([w isKindOfClass:ViewPortCanvas.class] && [w.receiveName isEqualToString:@"ViewPort"]) {
				ViewPortCanvas *cnv = (ViewPortCanvas *)w;
				cnv.delegate = nil;
			}
		}
	}
	if(self.background) {
		[self clearBackground];
	}
	[super close];
}

- (void)reshape {
	[super reshape];
	if(self.background) {
		[self reshapeBackground];
	}
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	if(self.hasInfo) {
		NSString *n = info[@"name"];
		if(n) {
			return n;
		}
	}
	return self.patch.pathName.lastPathComponent;
}

- (BOOL)hasInfo {
	return (info != nil);
}

- (NSString *)artist {
	if(self.hasInfo) {
		NSString *a = info[@"author"];
		if(a) {
			return a;
		}
	}
	return [super artist];
}

- (NSString *)category {
	if(self.hasInfo) {
		NSString *c = info[@"category"];
		if(c) {
			return c;
		}
	}
	return [super category];
}

- (NSString *)description {
	if(self.hasInfo) {
		NSString *d = info[@"description"];
		if(d) {
			return d;
		}
	}
	return [super description];
}

- (NSString *)type {
	return @"PartyScene";
}

- (BOOL)supportsDynamicBackground {
	return YES;
}

#pragma mark Util

+ (BOOL)isPdPartyDirectory:(NSString *)fullpath {
	return [NSFileManager.defaultManager fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"_main.pd"]];
}

+ (UIImage *)thumbnailForSceneAt:(NSString *)fullpath {
	NSArray *imagePaths = [Util whichFilenames:@[@"thumb.png", @"Thumb.png", @"thumb.jpg", @"Thumb.jpg"] existInDirectory:fullpath];
	if(imagePaths) {
		return [[UIImage alloc] initWithContentsOfFile:[fullpath stringByAppendingPathComponent:imagePaths.firstObject]];
	}
	return nil;
}

+ (NSDictionary *)infoForSceneAt:(NSString *)fullpath {
	NSArray *infoPaths = [Util whichFilenames:@[@"info.json", @"Info.json"] existInDirectory:fullpath];
	if(infoPaths) {
		return [Util parseJSONFromFile:[fullpath stringByAppendingPathComponent:infoPaths.firstObject]];
	}
	return nil;
}

@end
