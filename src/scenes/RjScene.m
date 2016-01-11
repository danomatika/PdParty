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
#import "RjScene.h"

#import "ControlsView.h"
#import "RjImage.h"
#import "RjText.h"

// TODO: decide on this
//#define IPAD_LANDSCAPE

@interface RjScene () {
	NSDictionary *info;
	NSMutableDictionary *widgets;
}

@property (assign, readwrite, nonatomic) float scale;

// find and remove abstractions which might mask rj-related internal patches
+ (void)removeRjAbstractionDuplicates:(NSString *)directory;

@end

@implementation RjScene

+ (id)sceneWithParent:(UIView *)parent andDispatcher:(PdDispatcher *)dispatcher {
	RjScene *s = [[RjScene alloc] init];
	s.parentView = parent;
	s.dispatcher = dispatcher;
	return s;
}

- (id)init {
	self = [super init];
    if(self) {
		widgets = [[NSMutableDictionary alloc] init];
		self.scale = 1.0f;
    }
    return self;
}

- (BOOL)open:(NSString *)path {
	
	[self.dispatcher addListener:self forSource:@"rj_image"];
	[self.dispatcher addListener:self forSource:@"rj_text"];
	
	[RjScene removeRjAbstractionDuplicates:path];
	
	if([super open:[path stringByAppendingPathComponent:@"_main.pd"]]) {
		
		#ifdef IPAD_LANDSCAPE
			// allow all orientations on iPad
			if([Util isDeviceATablet]) {
				self.preferredOrientations = UIInterfaceOrientationMaskAll;
			}
			else { // lock to portrait on iPhone
				self.preferredOrientations = UIInterfaceOrientationMaskPortrait;
			}
		#else
			self.preferredOrientations = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
		#endif
		
		// load background
		NSString *backgroundPath = [path stringByAppendingPathComponent:@"image.jpg"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:backgroundPath]) {
			DDLogWarn(@"RjScene: no background image, loading default background");
			backgroundPath = [[Util bundlePath] stringByAppendingPathComponent:@"images/rjdj_default.jpg"];
		}
		self.background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:backgroundPath]];
		if(!self.background.image) {
			DDLogError(@"RjScene: couldn't load background image");
		}
		self.background.contentMode = UIViewContentModeScaleAspectFill;
		[self.parentView addSubview:self.background];
		
		// load info
		NSString *infoPath = [path stringByAppendingPathComponent:@"Info.plist"];
		if([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
			info = [[NSDictionary dictionaryWithContentsOfFile:infoPath] objectForKey:@"info"];
			if(!info) {
				DDLogWarn(@"RjScene: couldn't load Info.plist");
			}
		}
		else {
			DDLogWarn(@"RjScene: no Info.plist");
		}
		
		return YES;
	}
	
	return NO;
}

- (void)close {
	
	[self.dispatcher removeListener:self forSource:@"rj_image"];
	[self.dispatcher removeListener:self forSource:@"rj_text"];
	
	if(self.background) {
		[self.background removeFromSuperview];
		self.background = nil;
	}
	
	[super close];
}

- (void)reshape {
	CGSize viewSize, backgroundSize, controlsSize;
	CGFloat xPos = 0;
	
	// rj backgrounds are always square
	viewSize = self.parentView.bounds.size;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
		backgroundSize.width = viewSize.width;
		backgroundSize.height = backgroundSize.width;
	}
	else {
		backgroundSize.width = round(viewSize.height * 0.8);
		backgroundSize.height = backgroundSize.width;
		xPos = round((viewSize.width - backgroundSize.width)/2);
	}
	
	// set background
	if(self.background) {
		self.background.frame = CGRectMake(xPos, 0, backgroundSize.width, backgroundSize.height);
		self.scale = backgroundSize.width / self.background.image.size.width;
	}
	
	// scale rj object positions and sizes
	NSArray *array = [widgets allValues];
	for(RjWidget *widget in array) {
		[widget reshape];
	}
}

- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	CGPoint p = [touch locationInView:self.background];
	if(![self.background pointInside:p withEvent:nil]) {
		return NO;
	}
	// rj scenes require 320x320 coord system
	pos->x = (int) (p.x/CGRectGetWidth(self.background.frame) * 320);
	pos->y = (int) (p.y/CGRectGetHeight(self.background.frame) * 320);
	return YES;
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	if(self.hasInfo) {
		NSString *n = [info objectForKey:@"name"];
		if(n) {
			return n;
		}
	}
	return [[self.patch.pathName lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL)hasInfo {
	return (BOOL) info;
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

- (SceneType)type {
	return SceneTypeRj;
}

- (NSString *)typeString {
	return @"RjScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = [UIColor blackColor];
			
			// add background & rj widgets to new parent view
			if(self.background) {
				[self.parentView addSubview:self.background];
			}
		}
	}
}

- (int)sampleRate {
	return RJ_SAMPLERATE;
}

// accel is always on
- (BOOL)requiresAccel {
	return YES;
}

- (BOOL)supportsAccel {
	return NO;
}

- (BOOL)supportsGyro {
	return NO;
}

- (BOOL)supportsMagnet {
	return NO;
}

- (BOOL)supportsLocate {
	return NO;
}

- (BOOL)supportsHeading {
	return NO;
}

- (BOOL)requiresKeys {
	return NO;
}

- (BOOL)requiresOnscreenControls {
	return YES;
}

- (int)contentHeight {
	return CGRectGetHeight(self.background.bounds);
}

#pragma mark Util

+ (BOOL)isRjDjDirectory:(NSString *)fullpath {
	if([[fullpath pathExtension] isEqualToString:@"rj"] &&
		[[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"_main.pd"]]) {
		return YES;
	}
	return NO;
}

+ (UIImage*)thumbnailForSceneAt:(NSString *)fullpath {
	if([[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"thumb.jpg"]]) {
		return [[UIImage alloc] initWithContentsOfFile:[fullpath stringByAppendingPathComponent:@"thumb.jpg"]];
	}
	else if([[NSFileManager defaultManager] fileExistsAtPath:[fullpath stringByAppendingPathComponent:@"image.jpg"]]) {
		return [[UIImage alloc] initWithContentsOfFile:[fullpath stringByAppendingPathComponent:@"image.jpg"]];
	}
	return nil;
}

+ (NSDictionary*)infoForSceneAt:(NSString *)fullpath {
	NSString *infoPath = [fullpath stringByAppendingPathComponent:@"Info.plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
		return [[NSDictionary dictionaryWithContentsOfFile:infoPath] objectForKey:@"info"];
	}
	return nil;
}

#pragma mark WidgetListener

// mostly borrowed from the pd-for-android ScenePlayer
- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count < 2 || ![list isStringAt:0] || ![list isStringAt:1]) return;
	
	NSString *key = [list objectAtIndex:0];
	NSString *cmd = [list objectAtIndex:1];
	
	RjWidget *widget = [widgets valueForKey:key];
	if(widget) {
		if([cmd isEqualToString:@"visible"]) {
			if(list.count < 3 || ![list isNumberAt:2]) return;
			widget.hidden = ![[list objectAtIndex:2] floatValue] > 0.5f;
		}
		else if([cmd isEqualToString:@"move"]) {
			if(list.count < 4 || ![list isNumberAt:2] || ![list isNumberAt:3]) return;
			widget.position = CGPointMake([[list objectAtIndex:2] floatValue],
										  [[list objectAtIndex:3] floatValue]);
		}
		else {
			if([widget isKindOfClass:[RjImage class]]) {
				if(list.count < 3 || ![list isNumberAt:2]) return;
				RjImage *image = (RjImage *) widget;
				float val = [[list objectAtIndex:2] floatValue];
				if([cmd isEqualToString:@"ref"]) {
					image.centered = val > 0.5f;
				}
				else if([cmd isEqualToString:@"scale"]) {
					if(list.count < 4 || ![list isNumberAt:3]) return;
					[image setScaleX:val andY:[[list objectAtIndex:3] floatValue]];
				}
				else if([cmd isEqualToString:@"rotate"]) {
					image.angle = val;
				}
				else if([cmd isEqualToString:@"alpha"]) {
					image.alpha = val;
				}
			}
			else if([widget isKindOfClass:[RjText class]]) {
				RjText *text = (RjText *) widget;
				if([cmd isEqualToString:@"text"]) {
					if(list.count < 3 || ![list isStringAt:2]) return;
					text.text = [list objectAtIndex:2];
				}
				else if([cmd isEqualToString:@"size"]) {
					if(list.count < 3 || ![list isNumberAt:2]) return;
					text.fontSize = [[list objectAtIndex:2] floatValue];
				}
			}
		}
	}
	else {
		if(list.count < 3 || ![list isStringAt:2]) return;
		NSString *arg = [list objectAtIndex:2];
		if([cmd isEqualToString:@"load"]) {
			widget = [RjImage imageWithFile:[self.patch.pathName stringByAppendingPathComponent:arg] andParent:self];
			if(!widget) return;
			DDLogVerbose(@"RjScene: loading RjImage %@", arg);
		}
		else if([cmd isEqualToString:@"text"]) {
			widget = [RjText textWithText:arg andParent:self];
			if(!widget) return;
			DDLogVerbose(@"RjScene: loading RjText %@", arg);
		}
		else return;
		[self.background addSubview:widget];
		[self.background bringSubviewToFront:widget];
		[widgets setValue:widget forKey:key];
		DDLogVerbose(@"RjScene: added %@ with key: %@", widget.typeString, key);
	}
}

#pragma mark Private

// weird little hack to avoid having our rj_image.pd and such masked by files in the scene,
// from pd-for-android ScenePlayer
+ (void)removeRjAbstractionDuplicates:(NSString *)directory {

	NSArray *contents = [[NSFileManager defaultManager] subpathsAtPath:directory];
	if(!contents) {
		return;
	}
	
	// loop through returned paths and remove any matching patches
	NSError *error;
	for(NSString *path in contents) {
		NSString *file = [path lastPathComponent];
		if([file isEqualToString:@"rj_image.pd"] || [file isEqualToString:@"rj_text.pd"] ||
		   [file isEqualToString:@"soundinput.pd"] || [file isEqualToString:@"soundoutput.pd"]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:path] error:&error]) {
				DDLogError(@"RJScene: couldn't remove %@, error: %@", path, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"RJScene: removed %@", file);
			}
		}
	}
}

@end
