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
#include "PatchScene.h"

#import "AppDelegate.h"

#define CHECK_SOUNDOUTPUT

@interface PatchScene () {
	BOOL soundoutputFound;
}
@end

@implementation PatchScene

+ (id)sceneWithParent:(UIView *)parent andGui:(Gui *)gui {
	PatchScene *s = [[PatchScene alloc] init];
	s.parentView = parent;
	s.gui = gui;
	return s;
}

- (BOOL)open:(NSString *)path {
	NSString *fileName = path.lastPathComponent;
	NSString *dirPath = path.stringByDeletingLastPathComponent;
	
	[self addSearchPathsIn:[Util.bundlePath stringByAppendingPathComponent:@"patches/lib"]];
	[self addSearchPathsIn:[Util.documentsPath stringByAppendingPathComponent:@"lib"]];
	[PdBase addToSearchPath:dirPath];
	
	// add widgets before loading patch so dollar args can be replaced later
	[self.gui addWidgetsFromPatch:path];
	self.preferredOrientations = [Scene orientationMaskFromWidth:self.gui.patchWidth andHeight:self.gui.patchHeight];
	
	LogVerbose(@"%@: opening %@ %@", self.type, fileName, dirPath);
	
	// load patch
	self.patch = [PdFile openFileNamed:fileName path:dirPath];
	if(!self.patch) {
		LogError(@"%@: couldn't open %@ %@", self.type, fileName, dirPath);
		[self.gui removeAllWidgets];
		return NO;
	}
	
	// check for [soundoutput] which is used for recording
	#ifdef CHECK_SOUNDOUTPUT
		soundoutputFound = [PureData objectExists:@"soundoutput" inPatch:self.patch];
		LogVerbose(@"%@: soundoutput found: %@", self.type, (soundoutputFound ? @"yes" : @"no"));
	#else
		soundoutputFound = YES:
	#endif
	
	// load widgets from gui
	if(self.parentView) {
		if(self.gui.widgets.count > 0) {
			LogVerbose(@"%@: adding %lu widgets", self.type, (unsigned long)self.gui.widgets.count);
		}
		[self.gui initWidgetsFromPatch:self.patch andAddToView:self.parentView];
	}

	// find ViewPort cnv and set as delegate
	if(self.requiresViewport) {
		for(Widget *w in self.gui.widgets) {
			if([w isKindOfClass:ViewPortCanvas.class] && [w.receiveName isEqualToString:@"ViewPort"]) {
				ViewPortCanvas *cnv = (ViewPortCanvas *)w;
				cnv.delegate = self;
				LogInfo(@"%@: found ViewPort canvas", self.type);
			}
		}
	}
	
	return YES;
}

- (void)close {
	if(self.patch && [self.patch isValid]) {
		[self.patch closeFile];
		if(self.gui) {
			[self.gui removeWidgetsFromSuperview];
			[self.gui removeAllWidgets];
			self.gui.fontName = nil; // reset to default font
			self.gui = nil;
			self.parentView = nil;
		}
		[PdBase clearSearchPath];
		LogVerbose(@"%@: closed", self.type);
	}
}

- (void)reshape {
	[self.gui reshapeWidgets];
}

// normalize to whole view
- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	pos->x = pos->x / CGRectGetWidth(self.parentView.frame);
	pos->y = pos->y / CGRectGetHeight(self.parentView.frame);
	return YES;
}

+ (BOOL)isPatchFile:(NSString *)fullpath {
	return [fullpath.pathExtension isEqualToString:@"pd"];
}

- (BOOL)requiresSensor:(SensorType)sensor {
	return NO;
}

- (BOOL)supportsSensor:(SensorType)sensor {
	return YES;
}

#pragma Background

- (BOOL)supportsDynamicBackground {
	return NO;
}

- (BOOL)loadBackground:(NSString *)fullpath {
	if([NSFileManager.defaultManager fileExistsAtPath:fullpath]) {
		if(!self.background) {
			self.background = [[UIImageView alloc] init];
		}
		UIImage *image = [UIImage imageWithContentsOfFile:fullpath];
		if(image) {
			self.background.image = image;
			[self reshapeBackground];
			self.background.contentMode = UIViewContentModeScaleAspectFill;
			[self.parentView addSubview:self.background];
			[self.parentView sendSubviewToBack:self.background];
			return YES;
		}
		else {
			self.background.image = nil;
		}
	}
	return NO;
}

- (void)clearBackground {
	if(self.background) {
		[self.background removeFromSuperview];
		self.background = nil;
	}
}

- (void)reshapeBackground {
	self.background.frame = CGRectMake(
		0, 0,
		CGRectGetWidth(self.parentView.bounds),
		CGRectGetHeight(self.parentView.bounds)
	);
}

#pragma mark Font

- (BOOL)loadFont:(NSString *)fontPath {
	if([NSFileManager.defaultManager fileExistsAtPath:fontPath]) {
		NSString *fontName = [Util registerFont:fontPath];
		if(fontName) {
			self.fontPath = fontPath;
			self.gui.fontName = fontName;
			return YES;
		}
	}
	return NO;
}

- (void)clearFont {
	if(self.fontPath) {
		[Util unregisterFont:self.fontPath];
		self.fontPath = nil;
	}
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return self.patch.baseName.stringByDeletingPathExtension;
}

- (BOOL)records {
	return soundoutputFound;
}

- (NSString *)type {
	return @"PatchScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = UIColor.whiteColor;
			
			// add widgets to new parent view
			if(self.gui) {
				[self.gui removeWidgetsFromSuperview];
				for(Widget *widget in self.gui.widgets) {
					[self.parentView addSubview:widget];
				}
			}
		}
	}
}

- (BOOL)requiresTouch {
	return YES;
}

- (BOOL)requiresControllers {
	return YES;
}

- (BOOL)requiresShake {
	return YES;
}

- (BOOL)requiresKeys {
	return YES;
}

- (BOOL)requiresViewport {
	return YES;
}

#pragma mark ViewPortDelegate

- (void)receivePositionX:(float)x Y:(float)y {
	self.gui.viewport = CGRectMake(x, y,
		CGRectGetWidth(self.gui.viewport), CGRectGetHeight(self.gui.viewport));
	[self.gui reshapeWidgets];
	[self.parentView setNeedsDisplay];
}

- (void)receiveSizeW:(float)w H:(float)h {
	self.gui.viewport = CGRectMake(self.gui.viewport.origin.x, self.gui.viewport.origin.y, w, h);
	[self.gui reshapeWidgets];
	[self.parentView setNeedsDisplay];
}

@end
