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
#import "Gui.h"
#import "AppDelegate.h"

#define ACCEL_UPDATE_HZ	60.0

@interface SceneManager () {
	
	CMMotionManager *motionManager; // for accel data
	
	CLLocationManager *locationManager; // for location data
	BOOL hasIgnoredStartingLocation; // ignore the initial, old location
	NSDateFormatter *locationDateFormatter;
	
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
		
		// init motion manager
		motionManager = [[CMMotionManager alloc] init];
		
		// current UI orientation for accel
		if([Util isDeviceATablet]) { // iPad can started rotated
			self.currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
		}
		else { // do not start rotated on iPhone
			self.currentOrientation = UIInterfaceOrientationPortrait;
		}
		
		// init location manager
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		
		// set osc and pure data pointer
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		self.osc = app.osc;
		self.pureData = app.pureData;
		
		// create gui
		self.gui = [[Gui alloc] init];
	}
		
	return self;
}

- (BOOL)openScene:(NSString *)path withType:(SceneType)type forParent:(UIView *)parent {
	if([self.currentPath isEqualToString:path]) {
		DDLogVerbose(@"SceneManager openScene: ignoring scene with same path");
		return NO;
	}
	
	// close open scene
	[self closeScene];
	
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
	self.enableAccelerometer = self.scene.requiresAccel;
	self.enableLocation = self.scene.requiresLocate;
	self.pureData.playing = YES;
	[self.scene open:path];
	
	// turn up volume & turn on transport, update gui
	[self.pureData sendCurrentPlayValues];
	
	// store current location
	self.currentPath = path;
	
	return YES;
}

- (void)closeScene {
	if(self.scene) {
		if(self.pureData.isRecording) {
			[self.pureData stopRecording];
		}
		[PureData sendCloseBang];
		[self.scene close];
		self.scene = nil;
		self.enableAccelerometer = NO;
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

- (void)setEnableAccelerometer:(BOOL)enableAccelerometer {
	if(self.enableAccelerometer == enableAccelerometer) {
		return;
	}
	_enableAccelerometer = enableAccelerometer;
	
	// start
	if(enableAccelerometer) {
		if([motionManager isAccelerometerAvailable]) {
			NSTimeInterval updateInterval = 1.0/ACCEL_UPDATE_HZ;
			[motionManager setAccelerometerUpdateInterval:updateInterval];
			
			// accel data callback block
			[motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
//					DDLogVerbose(@"accel %f %f %f", accelerometerData.acceleration.x,
//													accelerometerData.acceleration.y,
//													accelerometerData.acceleration.z);
					// orient accel data to current orientation
					switch(self.currentOrientation) {
						case UIInterfaceOrientationPortrait:
							[PureData sendAccel:accelerometerData.acceleration.x
											  y:accelerometerData.acceleration.y
											  z:accelerometerData.acceleration.z];
							[self.osc sendAccel:accelerometerData.acceleration.x
											  y:accelerometerData.acceleration.y
											  z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationLandscapeRight:
							[PureData sendAccel:-accelerometerData.acceleration.y
											  y:accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							[self.osc sendAccel:-accelerometerData.acceleration.y
											  y:accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationPortraitUpsideDown:
							[PureData sendAccel:-accelerometerData.acceleration.x
											  y:-accelerometerData.acceleration.y
											  z:accelerometerData.acceleration.z];
							[self.osc sendAccel:-accelerometerData.acceleration.x
											  y:-accelerometerData.acceleration.y
											  z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationLandscapeLeft:
							[PureData sendAccel:accelerometerData.acceleration.y
											  y:-accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							[self.osc sendAccel:accelerometerData.acceleration.y
											  y:-accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							break;
					}
				}];
			DDLogVerbose(@"SceneManager: enabled accel");
		}
		else {
			DDLogWarn(@"SceneManager: couldn't enable accel, accel not available on this device");
		}
	}
	else { // stop
		if([motionManager isAccelerometerActive]) {
			[motionManager stopAccelerometerUpdates];
			DDLogVerbose(@"SceneManager: disabled accel");
		}
	}
}

- (void)setEnableLocation:(BOOL)enableLocation {
	if(self.enableLocation == enableLocation) {
		return;
	}
	_enableLocation = enableLocation;
	
	// start
	if(enableLocation) {
		if([CLLocationManager locationServicesEnabled]) {
			
			hasIgnoredStartingLocation = NO;
			
			locationDateFormatter = [[NSDateFormatter alloc] init];
			[locationDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
			
			[locationManager startUpdatingLocation];
			
			DDLogVerbose(@"SceneManager: enabled accel");
		}
		else {
			DDLogWarn(@"SceneManager: couldn't enable locate, location services not available on this device");
		}
	}
	else { // stop
		if([CLLocationManager locationServicesEnabled]) {
			[locationManager stopUpdatingLocation];
			locationDateFormatter = nil;
			DDLogVerbose(@"SceneManager: disabled accel");
		}
	}
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	
	NSString *statusString;
	switch(status) {
		
		case kCLAuthorizationStatusRestricted:
			statusString = @"Restricted";
			if([CLLocationManager locationServicesEnabled]) {
				[locationManager stopUpdatingLocation];
			}
			break;
   
		case kCLAuthorizationStatusDenied:
			if([CLLocationManager locationServicesEnabled]) {
				[locationManager stopUpdatingLocation];
			}
			statusString = @"Denied";
			break;
		
		case kCLAuthorizationStatusAuthorized:
			statusString = @"Authorized";
			break;
		
		default:
			statusString = @"Not Determined";
			break;
	}
	DDLogVerbose(@"SceneManager: location authorization: %@", statusString);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

	// ignore stale stored location when starting
	if(!hasIgnoredStartingLocation) {
		CLLocation *location = [locations objectAtIndex:0];
		if(abs([location.timestamp timeIntervalSinceNow]) > 1.0) {
			hasIgnoredStartingLocation = YES;
			return; // assume there aren't any extra locations in the array
		}
	}
	
	// handle locations, oldest is first
	for(CLLocation *location in locations) {
		
		DDLogVerbose(@"locate %@", location.description);
		
		NSString *timestamp = [locationDateFormatter stringFromDate:location.timestamp];
		
		[PureData sendLocate:location.coordinate.latitude
						 lon:location.coordinate.longitude
						 alt:location.altitude
					   speed:location.speed
				horzAccuracy:location.horizontalAccuracy
				vertAccuracy:location.verticalAccuracy
				   timestamp:timestamp];
		
		[self.osc sendLocate:location.coordinate.latitude
						 lon:location.coordinate.longitude
						 alt:location.altitude
					   speed:location.speed
				horzAccuracy:location.horizontalAccuracy
				vertAccuracy:location.verticalAccuracy
				   timestamp:timestamp];
	}
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
	DDLogVerbose(@"SceneManager: location updates paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	DDLogVerbose(@"SceneManager: location updates resumed");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	DDLogError(@"SceneManager: location manager error: %@", error.localizedDescription);
}

@end