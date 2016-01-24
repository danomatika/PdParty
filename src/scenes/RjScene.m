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
#define IPAD_ALLOW_LANDSCAPE

@interface RjScene () {
	NSDictionary *info;
	NSMutableDictionary *widgets;
	BOOL requiresLocation;
	BOOL requiresCompass;
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
		
		#ifdef IPAD_ALLOW_LANDSCAPE
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
		if(self.background.image) { // don't smooth when scaling
			self.background.layer.magnificationFilter = kCAFilterNearest;
			self.background.layer.shouldRasterize = YES;
		}
		else {
			DDLogError(@"RjScene: couldn't load background image");
		}
		self.background.contentMode = UIViewContentModeScaleAspectFill;
		[self.parentView addSubview:self.background];
		
		// load info
		info = [RjScene infoForSceneAt:path];
		if(info) {
			DDLogInfo(@"RjScene: loaded info");
		}
		else {
			DDLogError(@"RjScene: couldn't load info");
		}
		
		// check sensor requirements
		requiresLocation = [PureData objectExists:@"rj_loc" inPatch:self.patch];
		requiresCompass = [PureData objectExists:@"rj_compass" inPatch:self.patch];
		
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
	for(RjWidget *widget in [widgets allValues]) {
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

- (BOOL)requiresSensor:(SensorType)sensor {
	switch(sensor) {
		case SensorTypeAccel:
			return YES;
		case SensorTypeGyro:
			return YES;
		case SensorTypeLocation:
			return requiresLocation;
		case SensorTypeCompass:
			return requiresCompass;
		default:
			return [super requiresSensor:sensor];
	}
}

- (BOOL)supportsSensor:(SensorType)sensor {
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
	return [[self.patch.pathName lastPathComponent] stringByDeletingPathExtension];
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
	NSArray *imagePaths = [Util whichFilenames:@[@"thumb.jpg", @"Thumb.jpg", @"image.jpg", @"Image.jpg"] existInDirectory:fullpath];
	if(imagePaths) {
		return [[UIImage alloc] initWithContentsOfFile:[fullpath stringByAppendingPathComponent:[imagePaths firstObject]]];
	}
	return nil;
}

+ (NSDictionary*)infoForSceneAt:(NSString *)fullpath {
	NSArray *infoPaths = [Util whichFilenames:@[@"Info.plist", @"info.plist"] existInDirectory:fullpath];
	if(infoPaths) {
		return [[NSDictionary dictionaryWithContentsOfFile:[fullpath stringByAppendingPathComponent:[infoPaths firstObject]]] objectForKey:@"info"];
	}
	return nil;
}

#pragma mark WidgetListener

// mostly borrowed from the pd-for-android ScenePlayer
- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count < 2 || ![list isStringAt:0] || ![list isStringAt:1]) {
		return;
	}
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
					if(list.count < 3) return;
					text.text = [[list subarrayWithRange:NSMakeRange(2, list.count-2)] componentsJoinedByString:@" "];
				}
				else if([cmd isEqualToString:@"size"]) {
					if(list.count < 3 || ![list isNumberAt:2]) return;
					text.fontSize = [[list objectAtIndex:2] floatValue];
				}
			}
		}
	}
	else {
		if(list.count < 3) return;
		NSString *arg = [[list subarrayWithRange:NSMakeRange(2, list.count-2)] componentsJoinedByString:@" "];
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
		DDLogVerbose(@"RjScene: added %@ with key: %@", widget.type, key);
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
		   [file isEqualToString:@"rj_compass.pd"] || [file isEqualToString:@"rj_loc.pd"] || [file isEqualToString:@"rj_time.pd"] ||
		   [file isEqualToString:@"soundinput.pd"] || [file isEqualToString:@"soundoutput.pd"]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:path] error:&error]) {
				DDLogError(@"RjScene: couldn't remove %@, error: %@", path, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"RjScene: removed %@", file);
			}
		}
	}
}

@end
