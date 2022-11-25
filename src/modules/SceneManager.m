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
	BOOL hasReshaped; //< has the gui been reshaped?
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
		if(Util.isDeviceATablet) { // iPad can started rotated
			self.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
		else { // do not start rotated on iPhone
			self.currentOrientation = UIInterfaceOrientationPortrait;
		}
		
		// set osc and pure data pointer
		AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
		self.osc = app.osc;
		self.pureData = app.pureData;
		self.pureData.sensorDelegate = self;
		
		// create sensor manager
		self.sensors = [[Sensors alloc] init];
		self.sensors.osc = app.osc;
		self.pureData.sensors = self.sensors;
		
		// create game controller manager
		if([Controllers controllersAvailable]) {
			self.controllers = [[Controllers alloc] init];
			self.controllers.osc = app.osc;
		}
		else {
			DDLogVerbose(@"SceneManager: game controller support not available on this device");
		}

		// listen for shake events
		NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
		[center addObserver:self selector:@selector(shakeEndedNotification:)
					   name:PdPartyMotionShakeEndedNotification object:nil];
		
		// create gui
		self.gui = [[PartyGui alloc] init];
	}
		
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self
	                                              name:PdPartyMotionShakeEndedNotification
	                                            object:nil];
	if(self.pureData) {
		self.pureData.sensorDelegate = nil;
	}
}

- (BOOL)openScene:(NSString *)path withType:(NSString *)type forParent:(UIView *)parent {
	return [self openScene:path withType:type forParent:parent allowReload:NO];
}

// helper
- (BOOL)openScene:(NSString *)path withType:(NSString *)type forParent:(UIView *)parent allowReload:(BOOL)reload {
	if(!reload && [self.currentPath isEqualToString:path]) {
		DDLogVerbose(@"SceneManager openScene: ignoring scene with same path");
		return NO;
	}
	
	// close open scene
	[self closeScene];
	
	// clear last scene's console
	[Log.textViewLogger clear];
	
	// set parent size if unset (aka first load on iPhone)
	if(self.gui.parentViewSize.width == 0 && self.gui.parentViewSize.height == 0) {
		[self reshapeToParentSize:parent.bounds.size];
	}
	[self.gui resetViewport];
	
	// open new scene
	if([type isEqualToString:@"PatchScene"]) {
		self.scene = [PatchScene sceneWithParent:parent andGui:self.gui];
	}
	else if([type isEqualToString:@"RjScene"]) {
		self.scene = [RjScene sceneWithParent:parent andDispatcher:self.pureData.dispatcher];
	}
	else if([type isEqualToString:@"DroidScene"]) {
		self.scene = [DroidScene sceneWithParent:parent andGui:self.gui];
	}
	else if([type isEqualToString:@"PartyScene"]) {
		self.scene = [PartyScene sceneWithParent:parent andGui:self.gui];
	}
	else if([type isEqualToString:@"RecordingScene"]) {
		self.scene = [RecordingScene sceneWithParent:parent];
	}
	else {
		DDLogWarn(@"SceneManager: unknown scene type: %@", type);
		self.scene = [[Scene alloc] init];
	}
	if(self.scene.requiresPd) {
		self.pureData.audioEnabled = YES;
		if(self.scene.sampleRate == USER_SAMPLERATE) {
			self.pureData.sampleRate = [self.pureData userSampleRate];
		}
		else {
			self.pureData.sampleRate = self.scene.sampleRate;
		}
		self.pureData.playing = YES;
	}
	if([self.scene open:path]) {
		[self startRequiredSensors];
		self.controllers.enabled = self.scene.requiresControllers;
		DDLogVerbose(@"SceneManager: opened %@", self.scene.name);
	}
	else {
		DDLogError(@"SceneManager: couldn't open scene");
		[[UIAlertController alertControllerWithTitle:@"Open Failed"
											 message:@"Couldn't open scene, file, or recording."
								   cancelButtonTitle:@"Ok"] show];
		return NO;
	}
	
	// turn up volume & turn on transport, update gui
	if(self.scene.requiresPd) {
		[self.pureData sendCurrentPlayValues];
	}
	
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
	NSString *type = self.scene.type;
	UIView *parent = self.scene.parentView;
	[self closeScene];
	return [self openScene:self.currentPath withType:type forParent:parent allowReload:YES];
}

- (void)closeScene {
	if(self.scene) {
		if(self.pureData.isRecording) {
			[self.pureData stopRecording];
		}
		if(self.scene.requiresPd) {
			[PureData sendCloseBang];
		}
		[self.scene close];
		self.scene = nil;
		[self stopSensors];
		self.controllers.enabled = NO;
		hasReshaped = NO;
	}
}

- (void)reshapeToParentSize:(CGSize)size {
	self.gui.parentViewSize = size;
	if(!self.scene) {
		return;
	}
		
	// do animations if gui has already been set up once
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
	[self.osc sendTouch:eventType forId:id atX:x andY:y];
}

- (void)sendShake {
	if(self.scene.requiresShake) {
		[PureData sendShake];
	}
	[self.osc sendShake];
}

- (void)sendKey:(int)key {
	if(self.scene.requiresKeys) {
		[PureData sendKey:key];
	}
	[self.osc sendKey:key];
}

- (void)sendKeyUp:(int)key {
	if(self.scene.requiresKeys) {
		[PureData sendKeyUp:key];
	}
	[self.osc sendKeyUp:key];
}

#pragma mark Shake Notifications

- (void)shakeEndedNotification:(NSNotification *)notification {
	DDLogInfo(@"shake");
	[self sendShake];
}

#pragma mark PdSensorSupportDelegate

- (BOOL)supportsAccel {
	return [self.scene supportsSensor:SensorTypeAccel];
}

- (BOOL)supportsGyro {
	return [self.scene supportsSensor:SensorTypeGyro];
}

- (BOOL)supportsLocation {
	return [self.scene supportsSensor:SensorTypeLocation];
}

- (BOOL)supportsCompass {
	return [self.scene supportsSensor:SensorTypeCompass];
}

- (BOOL)supportsMagnet {
	return [self.scene supportsSensor:SensorTypeMagnet];
}

- (BOOL)supportsMotion {
	return [self.scene supportsSensor:SensorTypeMotion];
}

#pragma mark Overridden Getters / Setters

- (void)setPureData:(PureData *)pureData {
	if(_pureData) {
		_pureData.sensorDelegate = nil;
	}
	_pureData = pureData;
	_pureData.sensorDelegate = self;
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
	self.sensors.currentOrientation = currentOrientation;
}

- (UIInterfaceOrientation)currentOrientation {
	return self.sensors.currentOrientation;
}

#pragma mark Private

// most required sensors are manually polled
- (void)startRequiredSensors {
	if([self.scene requiresSensor:SensorTypeAccel]) {
		self.sensors.accelEnabled = YES;
	}
	if([self.scene requiresSensor:SensorTypeGyro]) {
		self.sensors.gyroAutoUpdates = YES;
		self.sensors.gyroEnabled = YES;
	}
	if([self.scene requiresSensor:SensorTypeLocation]) {
		self.sensors.locationAutoUpdates = NO;
		self.sensors.locationEnabled = YES;
	}
	if([self.scene requiresSensor:SensorTypeCompass]) {
		self.sensors.compassAutoUpdates = NO;
		self.sensors.compassEnabled = YES;
	}
	if([self.scene requiresSensor:SensorTypeMagnet]) {
		self.sensors.magnetAutoUpdates = NO;
		self.sensors.magnetEnabled = YES;
	}
	if([self.scene requiresSensor:SensorTypeMotion]) {
		self.sensors.magnetAutoUpdates = YES;
		self.sensors.motionEnabled = YES;
	}
}

// disable all & reset to defaults
- (void)stopSensors {
	self.sensors.accelEnabled = NO;
	self.sensors.gyroEnabled = NO;
	self.sensors.locationEnabled = NO;
	self.sensors.compassEnabled = NO;
	self.sensors.magnetEnabled = NO;
	self.sensors.motionEnabled = NO;
	[self.sensors reset];
}

@end
