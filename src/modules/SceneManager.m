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
 #import "SceneManager.h"

#import <CoreMotion/CoreMotion.h>
#import "Log.h"
#import "PartyGui.h"
#import "AppDelegate.h"
#import "TextViewLogger.h"

@interface SceneManager () {
	BOOL hasReshaped; // has the gui been reshaped?
}
@property (strong, readwrite, nonatomic) NSString* currentPath;
@property (assign, readwrite, getter=isRecording, nonatomic) BOOL recording;
@end

@implementation SceneManager

- (id)init {
	self = [super init];
	if(self) {
		hasReshaped = NO;
		
		// current UI orientation for accel
		if([Util isDeviceATablet]) { // iPad can started rotated
			self.currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
		}
		else { // do not start rotated on iPhone
			self.currentOrientation = UIInterfaceOrientationPortrait;
		}
		
		// set osc and pure data pointer
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		self.osc = app.osc;
		self.pureData = app.pureData;
		
		// create sensor manager
		self.sensors = [[Sensors alloc] init];
		self.sensors.sceneManager = self;
		
		// create gui
		self.gui = [[PartyGui alloc] init];
	}
		
	return self;
}

- (void)dealloc {
	if(self.pureData) {
		self.pureData.sensorDelegate = nil;
	}
}

- (BOOL)openScene:(NSString *)path withType:(SceneType)type forParent:(UIView *)parent {
	return [self openScene:path withType:type forParent:parent allowReload:NO];
}

// helper
- (BOOL)openScene:(NSString *)path withType:(SceneType)type forParent:(UIView *)parent allowReload:(BOOL)reload {
	if(!reload && [self.currentPath isEqualToString:path]) {
		DDLogVerbose(@"SceneManager openScene: ignoring scene with same path");
		return NO;
	}
	
	// close open scene
	[self closeScene];
	
	// clear last scene's console
	[[Log textViewLogger] clear];
	
	// open new scene
	switch(type) {
		case SceneTypePatch:
			self.scene = [PatchScene sceneWithParent:parent andGui:self.gui];
			break;
		case SceneTypeRj:
			self.scene = [RjScene sceneWithParent:parent andDispatcher:self.pureData.dispatcher];
			break;
		case SceneTypeDroid:
			self.scene = [DroidScene sceneWithParent:parent andGui:self.gui];
			break;
		case SceneTypeParty:
			self.scene = [PartyScene sceneWithParent:parent andGui:self.gui];
			break;
		case SceneTypeRecording:
			self.scene = [RecordingScene sceneWithParent:parent andPureData:self.pureData];
			break;
		default: // SceneTypeEmpty
			self.scene = [[Scene alloc] init];
			break;
	}
	self.pureData.audioEnabled = YES;
	self.pureData.sampleRate = self.scene.sampleRate;
	self.sensors.enableAccel = self.scene.requiresAccel;
	self.pureData.playing = YES;
	if([self.scene open:path]) {
		DDLogInfo(@"SceneManager: opened %@", self.scene.name);
	}
	
	// turn up volume & turn on transport, update gui
	[self.pureData sendCurrentPlayValues];
	
	// store current location
	self.currentPath = path;
	
	return YES;
}

- (BOOL)reloadScene {
	if(!self.scene) {
		DDLogVerbose(@"SceneManager reloadScene: ignoring empty scene reload");
		return NO;
	}
	DDLogVerbose(@"SceneManager: reloading %@", self.scene.name);
	SceneType type = self.scene.type;
	UIView *parent = self.scene.parentView;
	[self closeScene];
	return [self openScene:self.currentPath withType:type forParent:parent allowReload:YES];
}

- (void)closeScene {
	if(self.scene) {
		if(self.pureData.isRecording) {
			[self.pureData stopRecording];
		}
		[PureData sendCloseBang];
		[self.scene close];
		self.scene = nil;
		self.sensors.enableAccel = NO;
		self.sensors.enableMagnet = NO;
		self.sensors.enableGyro = NO;
		self.sensors.enableLocation = NO;
		self.sensors.enableHeading = NO;
		hasReshaped = NO;
	}
}

- (void)reshapeToParentSize:(CGSize)size {
	self.gui.parentViewSize = size;
	if(!self.scene) {
		return;
	}
		
	// do animations if gui has already been setup once
	// http://www.techotopia.com/index.php/Basic_iOS_4_iPhone_Animation_using_Core_Animation
	if(hasReshaped) {
		[UIView beginAnimations:nil context:nil];
	}
	[self.scene reshape];
	if(hasReshaped) {
		[UIView commitAnimations];
	}
	else {
		hasReshaped = YES;
	}
}

- (void)updateParent:(UIView *)parent {
	if(!self.scene) {
		return;
	}
	self.scene.parentView = parent;
}

#pragma mark Send Events

- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y {
	if(self.scene.requiresTouch) {
		[PureData sendTouch:eventType forId:id atX:x andY:y];
	}
	if(self.osc.isListening) {
		[self.osc sendTouch:eventType forId:id atX:x andY:y];
	}
}

// pd key event
- (void)sendKey:(int)key {
	if(self.scene.requiresKeys) {
		[PureData sendKey:key];
	}
	if(self.osc.isListening) {
		[self.osc sendKey:key];
	}
}

#pragma mark Overridden Getters / Setters

- (void)setPureData:(PureData *)pureData {
	if(_pureData) {
		_pureData.sensorDelegate = nil;
	}
	_pureData = pureData;
	_pureData.sensorDelegate = self.sensors;
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
	self.sensors.currentOrientation = currentOrientation;
}

- (UIInterfaceOrientation)currentOrientation {
	return self.sensors.currentOrientation;
}

@end