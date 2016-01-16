/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
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

// androidy update speed defines
#define SENSOR_UI_HZ      10.0
#define SENSOR_NORMAL_HZ  30.0
#define SENSOR_GAME_HZ    60.0
#define SENSOR_FASTEST_HZ 100.0

@interface Sensors () {
	CMMotionManager *motionManager; // for accel data
	CLLocationManager *locationManager; // for location data
	BOOL hasIgnoredStartingLocation; // ignore the initial, old location
	NSDateFormatter *locationDateFormatter, *headingDateFormatter;
}
@end

@implementation Sensors

- (id)init {
	self = [super init];
	if(self) {
		
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
	}
		
	return self;
}

#pragma mark Overridden Getters/Setters

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
	_currentOrientation = currentOrientation;
	// TODO: currently dosen't handle faceup / facedown UIDeviceOrientations
	locationManager.headingOrientation = currentOrientation;
}

- (void)setEnableAccel:(BOOL)enableAccel {
	if(self.enableAccel == enableAccel) {
		return;
	}
	_enableAccel = enableAccel;
	
	// start
	if(enableAccel) {
		if([motionManager isAccelerometerAvailable]) {
			NSTimeInterval interval = 1.0/SENSOR_NORMAL_HZ;
			[motionManager setAccelerometerUpdateInterval:interval];
			
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
							[self.sceneManager.osc sendAccel:accelerometerData.acceleration.x
														   y:accelerometerData.acceleration.y
														   z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationLandscapeRight:
							[PureData sendAccel:-accelerometerData.acceleration.y
											  y:accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							[self.sceneManager.osc sendAccel:-accelerometerData.acceleration.y
														   y:accelerometerData.acceleration.x
														   z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationPortraitUpsideDown:
							[PureData sendAccel:-accelerometerData.acceleration.x
											  y:-accelerometerData.acceleration.y
											  z:accelerometerData.acceleration.z];
							[self.sceneManager.osc sendAccel:-accelerometerData.acceleration.x
														   y:-accelerometerData.acceleration.y
														   z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationLandscapeLeft:
							[PureData sendAccel:accelerometerData.acceleration.y
											  y:-accelerometerData.acceleration.x
											  z:accelerometerData.acceleration.z];
							[self.sceneManager.osc sendAccel:accelerometerData.acceleration.y
														   y:-accelerometerData.acceleration.x
														   z:accelerometerData.acceleration.z];
							break;
						case UIInterfaceOrientationUnknown:
							break;
					}
				}];
			DDLogVerbose(@"Sensors: accel enabled");
		}
		else {
			DDLogWarn(@"Sensors: accel not available on this device");
		}
	}
	else { // stop
		if([motionManager isAccelerometerActive]) {
			[motionManager stopAccelerometerUpdates];
			DDLogVerbose(@"Sensors: accel disabled");
		}
	}
}

- (void)setEnableGyro:(BOOL)enableGyro {
	if(self.enableGyro == enableGyro) {
		return;
	}
	_enableGyro = enableGyro;
	
	NSString *msg;
	
	// start
	if(enableGyro) {
		if([motionManager isGyroAvailable]) {
			[motionManager setGyroUpdateInterval:1.0/SENSOR_NORMAL_HZ];
			
			// gyro data callback block
			[motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMGyroData *data, NSError *error) {
//				DDLogVerbose(@"gyro %f %f %f", data.rotationRate.x, data.rotationRate.y, data.rotationRate.z);
				[PureData sendGyro:data.rotationRate.x y:data.rotationRate.y z:data.rotationRate.z];
				[self.sceneManager.osc sendGyro:data.rotationRate.x y:data.rotationRate.y z:data.rotationRate.z];
			}];
			DDLogVerbose(@"Sensors: gyro enabled");
		}
		else {
			DDLogWarn(@"Sensors: gyro not available on this device");
		}
	}
	else { // stop
		if([motionManager isGyroActive]) {
			[motionManager stopGyroUpdates];
			DDLogVerbose(@"Sensors: gyro disabled");
		}
	}
}

- (void)setEnableMagnet:(BOOL)enableMagnet {
	if(self.enableMagnet == enableMagnet) {
		return;
	}
	_enableMagnet = enableMagnet;
	
	NSString *msg;
	
	// start
	if(enableMagnet) {
		if([motionManager isMagnetometerAvailable]) {
			[motionManager setMagnetometerUpdateInterval:1.0/SENSOR_NORMAL_HZ];
			
			// gyro data callback block
			[motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMMagnetometerData *data, NSError *error) {
//				DDLogVerbose(@"magnet %f %f %f", data.magneticField.x, data.magneticField.y, data.magneticField.z);
				[PureData sendMagnet:data.magneticField.x y:data.magneticField.y z:data.magneticField.z];
				[self.sceneManager.osc sendMagnet:data.magneticField.x y:data.magneticField.y z:data.magneticField.z];
			}];
			DDLogVerbose(@"Sensors: magnetometer enabled");
		}
		else {
			DDLogWarn(@"Sensors: magnetometer not available on this device");
		}
	}
	else { // stop
		if([motionManager isMagnetometerActive]) {
			[motionManager stopMagnetometerUpdates];
			DDLogVerbose(@"Sensors: magnetometer disabled");
		}
	}
}

- (void)setEnableLocation:(BOOL)enableLocation {
	if(self.enableLocation == enableLocation) {
		return;
	}
	_enableLocation = enableLocation;
	
	NSString *msg;
	
	// start
	if(enableLocation) {
		if([CLLocationManager locationServicesEnabled]) {
			
			hasIgnoredStartingLocation = NO;
			
			locationDateFormatter = [[NSDateFormatter alloc] init];
			[locationDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
			
			locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			locationManager.distanceFilter = kCLDistanceFilterNone;
			[locationManager startUpdatingLocation];
			[self.sceneManager.pureData sendPrint:@"locate enabled"];
		}
		else {
			[self.sceneManager.pureData sendPrint:@"location services disabled or not available on this device"];
		}
	}
	else { // stop
		if([CLLocationManager locationServicesEnabled]) {
			[locationManager stopUpdatingLocation];
			locationDateFormatter = nil;
			[self.sceneManager.pureData sendPrint:@"locate disabled"];
		}
	}
}

- (void)setEnableHeading:(BOOL)enableHeading {
	if(self.enableHeading == enableHeading) {
		return;
	}
	_enableHeading = enableHeading;
	
	NSString *msg;
	
	// start
	if(enableHeading) {
		if([CLLocationManager headingAvailable]) {
			
			headingDateFormatter = [[NSDateFormatter alloc] init];
			[headingDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
			
			locationManager.headingFilter = 1;
			[locationManager startUpdatingHeading];
			[self.sceneManager.pureData sendPrint:@"heading enabled"];
		}
		else {
			[self.sceneManager.pureData sendPrint:@"heading not available on this device"];
		}
	}
	else { // stop
		if([CLLocationManager headingAvailable]) {
			[locationManager stopUpdatingHeading];
			headingDateFormatter = nil;
			[self.sceneManager.pureData sendPrint:@"heading disabled"];
		}
	}
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	
	NSString *statusString;
	switch(status) {
		
		case kCLAuthorizationStatusRestricted:
			statusString = @"restricted";
			if([CLLocationManager locationServicesEnabled]) {
				[locationManager stopUpdatingLocation];
			}
			break;
   
		case kCLAuthorizationStatusDenied:
			if([CLLocationManager locationServicesEnabled]) {
				[locationManager stopUpdatingLocation];
			}
			statusString = @"denied";
			break;
		
		case kCLAuthorizationStatusAuthorized:
			statusString = @"authorized";
			break;
		
		default:
			statusString = @"not determined";
			break;
	}
	DDLogVerbose(@"Sensors: location authorization: %@", statusString);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

	// ignore stale stored location when starting
	if(!hasIgnoredStartingLocation) {
		CLLocation *location = [locations objectAtIndex:0];
		if(fabs([location.timestamp timeIntervalSinceNow]) > 1.0) {
			hasIgnoredStartingLocation = YES;
			return; // assume there aren't any extra locations in the array
		}
	}
	
	// handle locations, oldest is first
	for(CLLocation *location in locations) {
		
//		DDLogVerbose(@"locate %@", location.description);
		
		NSString *timestamp = [locationDateFormatter stringFromDate:location.timestamp];
		
		[PureData sendLocate:location.coordinate.latitude
						 lon:location.coordinate.longitude
						 alt:location.altitude
					   speed:location.speed
					   course:location.course
				horzAccuracy:location.horizontalAccuracy
				vertAccuracy:location.verticalAccuracy
				   timestamp:timestamp];
		
		[self.sceneManager.osc sendLocate:location.coordinate.latitude
									  lon:location.coordinate.longitude
									  alt:location.altitude
									speed:location.speed
								   course:location.course
							 horzAccuracy:location.horizontalAccuracy
							 vertAccuracy:location.verticalAccuracy
								timestamp:timestamp];
	}
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
	DDLogVerbose(@"Sensors: location updates paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	DDLogVerbose(@"Sensors: location updates resumed");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {

//	DDLogVerbose(@"heading %@", newHeading.description);
	
	NSString *timestamp = [headingDateFormatter stringFromDate:newHeading.timestamp];
	
	[PureData sendHeading:newHeading.magneticHeading
				 accuracy:newHeading.headingAccuracy
				timestamp:timestamp];
				
	[self.sceneManager.osc sendHeading:newHeading.magneticHeading
							  accuracy:newHeading.headingAccuracy
							 timestamp:timestamp];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	DDLogError(@"Sensors: location manager error: %@", error.localizedDescription);
}

#pragma mark PdLocationEventDelegate

- (void)startAccelUpdates {
	if(self.sceneManager.scene.supportsAccel) {
		self.enableAccel = YES;
	}
}

- (void)stopAccelUpdates {
	if(self.sceneManager.scene.supportsAccel) {
		self.enableAccel = NO;
	}
}

- (void)setAccelSpeed:(NSString *)speed {

	if([speed isEqualToString:@"slow"]) {
		[motionManager setAccelerometerUpdateInterval:1.0/SENSOR_UI_HZ];
	}
	else if([speed isEqualToString:@"normal"]) {
		[motionManager setAccelerometerUpdateInterval:1.0/SENSOR_NORMAL_HZ];
	}
	else if([speed isEqualToString:@"fast"]) {
		[motionManager setAccelerometerUpdateInterval:1.0/SENSOR_GAME_HZ];
	}
	else if([speed isEqualToString:@"fastest"]) {
		[motionManager setAccelerometerUpdateInterval:1.0/SENSOR_FASTEST_HZ];
	}
	else {
		[self.sceneManager.pureData sendPrint:[NSString stringWithFormat:@"ignoring unknown accelerate speed string: %@", speed]];
		return;
	}
	
	DDLogVerbose(@"Sensors: accel speed: %@", speed);
}

- (void)startGyroUpdates {
	if(self.sceneManager.scene.supportsGyro) {
		self.enableGyro = YES;
	}
}

- (void)stopGyroUpdates {
	if(self.sceneManager.scene.supportsGyro) {
		self.enableGyro = NO;
	}
}

- (void)setGyroSpeed:(NSString *)speed {

	if([speed isEqualToString:@"slow"]) {
		[motionManager setGyroUpdateInterval:1.0/SENSOR_UI_HZ];
	}
	else if([speed isEqualToString:@"normal"]) {
		[motionManager setGyroUpdateInterval:1.0/SENSOR_NORMAL_HZ];
	}
	else if([speed isEqualToString:@"fast"]) {
		[motionManager setGyroUpdateInterval:1.0/SENSOR_GAME_HZ];
	}
	else if([speed isEqualToString:@"fastest"]) {
		[motionManager setGyroUpdateInterval:1.0/SENSOR_FASTEST_HZ];
	}
	else {
		[self.sceneManager.pureData sendPrint:[NSString stringWithFormat:@"ignoring unknown gyro speed string: %@", speed]];
		return;
	}
	
	DDLogVerbose(@"Sensors: gyro speed: %@", speed);
}

- (void)startMagnetUpdates {
	if(self.sceneManager.scene.supportsMagnet) {
		self.enableMagnet = YES;
	}
}

- (void)stopMagnetUpdates {
	if(self.sceneManager.scene.supportsMagnet) {
		self.enableMagnet = NO;
	}
}

- (void)setMagnetSpeed:(NSString *)speed {

	if([speed isEqualToString:@"slow"]) {
		[motionManager setMagnetometerUpdateInterval:1.0/SENSOR_UI_HZ];
	}
	else if([speed isEqualToString:@"normal"]) {
		[motionManager setMagnetometerUpdateInterval:1.0/SENSOR_NORMAL_HZ];
	}
	else if([speed isEqualToString:@"fast"]) {
		[motionManager setMagnetometerUpdateInterval:1.0/SENSOR_GAME_HZ];
	}
	else if([speed isEqualToString:@"fastest"]) {
		[motionManager setMagnetometerUpdateInterval:1.0/SENSOR_FASTEST_HZ];
	}
	else {
		[self.sceneManager.pureData sendPrint:[NSString stringWithFormat:@"ignoring unknown magnet speed string: %@", speed]];
		return;
	}
	
	DDLogVerbose(@"Sensors: magnet speed: %@", speed);
}

- (void)startLocationUpdates {
	if(self.sceneManager.scene.supportsLocate) {
		self.enableLocation = YES;
	}
}

- (void)stopLocationUpdates {
	if(self.sceneManager.scene.supportsLocate) {
		self.enableLocation = NO;
	}
}

- (void)setLocationAccuracy:(NSString *)accuracy {
	
	if([accuracy isEqualToString:@"navigation"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
	}
	else if([accuracy isEqualToString:@"best"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	}
	else if([accuracy isEqualToString:@"10m"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
	}
	else if([accuracy isEqualToString:@"100m"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
	}
	else if([accuracy isEqualToString:@"1km"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
	}
	else if([accuracy isEqualToString:@"3km"]) {
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	}
	else {
		[self.sceneManager.pureData sendPrint:[NSString stringWithFormat:@"ignoring unknown locate accuracy string: %@", accuracy]];
		return;
	}
	
	DDLogVerbose(@"Sensors: location accuracy: %@", accuracy);
}

- (void)setLocationFilter:(float)distance {
	if(distance > 0 ) {
		locationManager.distanceFilter = distance;
		DDLogVerbose(@"Sensors: location distance filter: +/- %f", distance);
	}
	else { // clip 0 & negative values
		locationManager.distanceFilter = kCLDistanceFilterNone;
		DDLogVerbose(@"Sensors: location distance filter: none");
	}
}

- (void)startHeadingUpdates {
	if(self.sceneManager.scene.supportsHeading) {
		self.enableHeading = YES;
	}
}

- (void)stopHeadingUpdates {
	if(self.sceneManager.scene.supportsHeading) {
		self.enableHeading = NO;
	}
}

- (void)setHeadingFilter:(float)degrees {
	if(degrees > 0 ) {
		locationManager.headingFilter = degrees;
		DDLogVerbose(@"Sensors: heading filter: +/- %f", degrees);
	}
	else { // clip 0 & negative values
		locationManager.headingFilter = kCLHeadingFilterNone;
		DDLogVerbose(@"Sensors: heading filter: none");
	}
}

@end
