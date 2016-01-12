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

	NSString *fileName = [path lastPathComponent];
	NSString *dirPath = [path stringByDeletingLastPathComponent];
	
	[self addSearchPathsIn:[[Util bundlePath] stringByAppendingPathComponent:@"patches/lib"]];
	[self addSearchPathsIn:[[Util documentsPath] stringByAppendingPathComponent:@"lib"]];
	[PdBase addToSearchPath:dirPath];
	
	// add widgets before loading patch so dollar args can be replaced later
	[self.gui addWidgetsFromPatch:path];
	self.preferredOrientations = [Scene orientationMaskFromWidth:self.gui.patchWidth andHeight:self.gui.patchHeight];
	
	DDLogVerbose(@"%@: opening %@ %@", self.typeString, fileName, dirPath);
	
	// load patch
	self.patch = [PdFile openFileNamed:fileName path:dirPath];
	if(!self.patch) {
		DDLogError(@"%@: couldn't open %@ %@", self.typeString, fileName, dirPath);
		[self.gui removeAllWidgets];
		return NO;
	}
	
	// check for [soundoutput] which is used for recording
	soundoutputFound = [PureData objectExists:@"soundoutput" inPatch:self.patch];
	DDLogVerbose(@"%@: soundoutput found: %@", self.typeString, (soundoutputFound ? @"yes" : @"no"));
	
	// load widgets from gui
	if(self.parentView) {
		if(self.gui.widgets.count > 0) {
			DDLogVerbose(@"%@: adding %u widgets", self.typeString, self.gui.widgets.count);
		}
		[self.gui initWidgetsFromPatch:self.patch andAddToView:self.parentView];
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
		DDLogVerbose(@"%@: closed", self.typeString);
	}
}

- (void)reshape {
	[self.gui reshapeWidgets];
}

// normalize to whole view
- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos {
	pos->x = pos->x/CGRectGetWidth(self.parentView.frame);
	pos->y = pos->y/CGRectGetHeight(self.parentView.frame);
	return YES;
}

+ (BOOL)isPatchFile:(NSString *)fullpath {
	return [[fullpath pathExtension] isEqualToString:@"pd"];
}

#pragma mark Overridden Getters / Setters

- (NSString *)name {
	return [self.patch.baseName stringByDeletingPathExtension];
}

- (BOOL)records {
	return soundoutputFound;
}

- (SceneType)type {
	return SceneTypePatch;
}

- (NSString *)typeString {
	return @"PatchScene";
}

- (void)setParentView:(UIView *)parentView {
	if(self.parentView != parentView) {
		[super setParentView:parentView];
		if(self.parentView) {
			// set patch view background color
			self.parentView.backgroundColor = [UIColor whiteColor];
			
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

- (BOOL)supportsAccel {
	return YES;
}

- (BOOL)supportsGyro {
	return YES;
}

- (BOOL)supportsMagnet {
	return YES;
}

- (BOOL)supportsLocate {
	return YES;
}

- (BOOL)supportsHeading {
	return YES;
}

- (BOOL)requiresKeys {
	return YES;
}

@end
