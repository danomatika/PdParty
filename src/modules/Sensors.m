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
#import "Sensors.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreMotion/CMDeviceMotion.h>
#import "PureData.h"
#import "Osc.h"
#import "Util.h"
#import "Log.h"

// androidy update speed defines
#define SENSOR_UI_HZ      10.0
#define SENSOR_NORMAL_HZ  30.0
#define SENSOR_GAME_HZ    60.0
#define SENSOR_FASTEST_HZ 100.0

//#define DEBUG_SENSORS

@interface Sensors () {
	CMMotionManager *motionManager; ///< for sensor data
	NSOperationQueue *motionQueue; ///< processed motion queue
	CLLocationManager *locationManager; ///< for location data
	BOOL hasIgnoredStartingLocation; ///< ignore the initial, old location
}
@end

@implementation Sensors

- (id)init {
	self = [super init];
	if(self) {
		
		// init motion manager
		motionManager = [[CMMotionManager alloc] init];
		motionQueue = [[NSOperationQueue alloc] init];

		// init location manager
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		locationManager.allowsBackgroundLocationUpdates = YES;

		// current UI orientation for accel
		if(Util.isDeviceATablet) { // iPad can start rotated
			self.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
		else { // do not start rotated on iPhone
			self.currentOrientation = UIInterfaceOrientationPortrait;
		}
	
		[self reset];
	}
	return self;
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
	_currentOrientation = currentOrientation;
	[self updateLocationOrientation];
}

- (void)reset {
	self.accelSpeed = @"normal";
	self.accelOrientation = NO;
	self.gyroAutoUpdates = YES;
	self.gyroSpeed = @"normal";
	self.locationAutoUpdates = YES;
	self.locationAccuracy = @"best";
	self.locationFilter = 0;
	self.compassAutoUpdates = YES;
	self.compassFilter = 1;
	self.magnetAutoUpdates = YES;
	self.magnetSpeed = @"normal";
	self.motionSpeed = @"normal";
	self.motionAutoUpdates = YES;
}

#pragma mark Extended Touch

- (void)setExtendedTouchEnabled:(BOOL)extendedTouchEnabled {
	if(self.extendedTouchEnabled == extendedTouchEnabled) {
		return;
	}
	_extendedTouchEnabled = extendedTouchEnabled;
	LogVerbose(@"Sensors: extended touch %@",
	             (_extendedTouchEnabled ? @"enabled" : @"disabled"));
}

#pragma mark Accel

- (void)setAccelEnabled:(BOOL)accelEnabled {
	if(self.accelEnabled == accelEnabled) {
		return;
	}
	_accelEnabled = accelEnabled;
	if(accelEnabled) { // start
		if([motionManager isAccelerometerAvailable]) {
			[motionManager startAccelerometerUpdatesToQueue:motionQueue
				withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
					[self sendAccel:accelerometerData];
			}];
			LogVerbose(@"Sensors: accel enabled");
		}
		else {
			LogWarn(@"Sensors: accel not available on this device");
		}
	}
	else { // stop
		if([motionManager isAccelerometerActive]) {
			[motionManager stopAccelerometerUpdates];
			LogVerbose(@"Sensors: accel disabled");
		}
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
		[PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown accelerate speed string: %@", speed]];
		return;
	}
	LogVerbose(@"Sensors: accel speed: %@", speed);
}

#pragma mark Gyro

- (void)setGyroEnabled:(BOOL)gyroEnabled {
	if(self.gyroEnabled == gyroEnabled) {
		return;
	}
	_gyroEnabled = gyroEnabled;
	if(gyroEnabled) { // start
		if([motionManager isGyroAvailable]) {
			if(self.gyroAutoUpdates) {
				[motionManager startGyroUpdatesToQueue:motionQueue
					withHandler:^(CMGyroData *data, NSError *error) {
					[self sendGyro:data];
				}];
			}
			else {
				[motionManager startGyroUpdates];
			}
			LogVerbose(@"Sensors: gyro enabled");
		}
		else {
			LogWarn(@"Sensors: gyro not available on this device");
		}
	}
	else { // stop
		if([motionManager isGyroActive]) {
			[motionManager stopGyroUpdates];
			LogVerbose(@"Sensors: gyro disabled");
		}
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
		[PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown gyro speed string: %@", speed]];
		return;
	}
	LogVerbose(@"Sensors: gyro speed: %@", speed);
}

- (void)setGyroAutoUpdates:(BOOL)gyroAutoUpdates {
	if(_gyroAutoUpdates == gyroAutoUpdates) {return;}
	_gyroAutoUpdates = gyroAutoUpdates;
	if(motionManager.gyroActive) {
		[motionManager stopGyroUpdates];
		if(self.gyroAutoUpdates) {
			[motionManager startGyroUpdatesToQueue:motionQueue
				withHandler:^(CMGyroData *data, NSError *error) {
				[self sendGyro:data];
			}];
		}
		else {
			[motionManager startGyroUpdates];
		}
	}
	LogVerbose(@"Sensors: gyro updates: %d", (int)gyroAutoUpdates);
}

- (void)sendGyro {
	if(motionManager.gyroActive) {
		[self sendGyro:motionManager.gyroData];
	}
}

#pragma mark Location

- (void)setLocationEnabled:(BOOL)locationEnabled {
	if(self.locationEnabled == locationEnabled) {
		return;
	}
	_locationEnabled = locationEnabled;
	if(locationEnabled) { // start
		if([CLLocationManager locationServicesEnabled]) {
			hasIgnoredStartingLocation = NO;
			if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
				[PureData sendPrint:@"location denied"];
				NSString *message = @"To enable, please go to Settings and turn on Location Service for PdParty.";
				[[UIAlertController alertControllerWithTitle:@"Location Service Access Denied"
													 message:message
										   cancelButtonTitle:@"Ok"] show];
			}
			else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
				[PureData sendPrint:@"location restricted"];
				NSString *message = @"To enable, please go to Settings and turn off the Location Service restriction for PdParty.";
				[[UIAlertController alertControllerWithTitle:@"Location Service Access Restricted"
													 message:message
										   cancelButtonTitle:@"Ok"] show];
			}
			else {
				if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
					[locationManager requestWhenInUseAuthorization];
				}
				[locationManager startUpdatingLocation];
				[PureData sendPrint:@"location enabled"];
			}
		}
		else {
			[PureData sendPrint:@"location disabled or not available on this device"];
		}
	}
	else { // stop
		if([CLLocationManager locationServicesEnabled]) {
			[locationManager stopUpdatingLocation];
			[PureData sendPrint:@"location disabled"];
		}
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
		[PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown location accuracy string: %@", accuracy]];
		return;
	}
	LogVerbose(@"Sensors: location accuracy: %@", accuracy);
}

- (void)setLocationFilter:(float)distance {
	if(distance > 0 ) {
		locationManager.distanceFilter = distance;
		LogVerbose(@"Sensors: location distance filter: +/- %f", distance);
	}
	else { // clip 0 & negative values
		locationManager.distanceFilter = kCLDistanceFilterNone;
		LogVerbose(@"Sensors: location distance filter: none");
	}
}

- (void)sendLocation {
	if([CLLocationManager locationServicesEnabled]) {
		[self sendLocation:locationManager.location];
	}
}

#pragma mark Compass

- (void)setCompassEnabled:(BOOL)compassEnabled {
	if(self.compassEnabled == compassEnabled) {
		return;
	}
	_compassEnabled = compassEnabled;
	if(compassEnabled) { // start
		if([CLLocationManager headingAvailable]) {
			[locationManager startUpdatingHeading];
			[PureData sendPrint:@"compass enabled"];
		}
		else {
			[PureData sendPrint:@"compass not available on this device"];
		}
	}
	else { // stop
		if([CLLocationManager headingAvailable]) {
			[locationManager stopUpdatingHeading];
			[PureData sendPrint:@"compass disabled"];
		}
	}
}

- (void)setCompassFilter:(float)degrees {
	if(degrees > 0 ) {
		locationManager.headingFilter = degrees;
		LogVerbose(@"Sensors: compass filter: +/- %f", degrees);
	}
	else { // clip 0 & negative values
		locationManager.headingFilter = kCLHeadingFilterNone;
		LogVerbose(@"Sensors: compass filter: none");
	}
}

- (void)sendCompass {
	if([CLLocationManager headingAvailable]) {
		[self sendCompass:locationManager.heading];
	}
}

#pragma mark Magnet

- (void)setMagnetEnabled:(BOOL)magnetEnabled {
	if(self.magnetEnabled == magnetEnabled) {
		return;
	}
	_magnetEnabled = magnetEnabled;
	if(magnetEnabled) { // start
		if([motionManager isMagnetometerAvailable]) {
			if(self.magnetAutoUpdates) {
				[motionManager startMagnetometerUpdatesToQueue:motionQueue
					withHandler:^(CMMagnetometerData *data, NSError *error) {
					[self sendMagnet:data];
				}];
			}
			else {
				[motionManager startMagnetometerUpdates];
			}
			LogVerbose(@"Sensors: magnetometer enabled");
		}
		else {
			LogWarn(@"Sensors: magnetometer not available on this device");
		}
	}
	else { // stop
		if([motionManager isMagnetometerActive]) {
			[motionManager stopMagnetometerUpdates];
			LogVerbose(@"Sensors: magnetometer disabled");
		}
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
		[PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown magnet speed string: %@", speed]];
		return;
	}
	LogVerbose(@"Sensors: magnet speed: %@", speed);
}

- (void)setMagnetAutoUpdates:(BOOL)magnetAutoUpdates {
	if(_magnetAutoUpdates == magnetAutoUpdates) {return;}
	_magnetAutoUpdates = magnetAutoUpdates;
	if(motionManager.magnetometerActive) {
		[motionManager stopMagnetometerUpdates];
		if(self.magnetAutoUpdates) {
			[motionManager startMagnetometerUpdatesToQueue:motionQueue
				withHandler:^(CMMagnetometerData *data, NSError *error) {
				[self sendMagnet:data];
			}];
		}
		else {
			[motionManager startMagnetometerUpdates];
		}
	}
	LogVerbose(@"Sensors: magnet updates: %d", (int)magnetAutoUpdates);
}

- (void)sendMagnet {
	if(motionManager.magnetometerActive) {
		[self sendMagnet:motionManager.magnetometerData];
	}
}

#pragma mark Motion

 - (void)setMotionEnabled:(BOOL)motionEnabled {
	if(self.motionEnabled == motionEnabled) {
		return;
	}
	_motionEnabled = motionEnabled;
	if(motionEnabled) {
		if([motionManager isDeviceMotionAvailable]) {
			if(self.motionAutoUpdates) {
				[motionManager startDeviceMotionUpdatesToQueue:motionQueue
				                                   withHandler:^(CMDeviceMotion *data, NSError *error) {
					[self sendMotion:data];
				}];
			}
			else {
				[motionManager startDeviceMotionUpdates];
			}
			LogVerbose(@"Sensors: motion enabled");
		}
		else {
			LogWarn(@"Sensors: motion not available on this device");
		}
	}
	else { // stop
		if([motionManager isDeviceMotionActive]) {
			[motionManager stopDeviceMotionUpdates];
			LogVerbose(@"Sensors: motion disabled");
		}
	}
}

- (void)setMotionSpeed:(NSString *)speed {
	if([speed isEqualToString:@"slow"]) {
		[motionManager setDeviceMotionUpdateInterval:1.0/SENSOR_UI_HZ];
	}
	else if([speed isEqualToString:@"normal"]) {
		[motionManager setDeviceMotionUpdateInterval:1.0/SENSOR_NORMAL_HZ];
	}
	else if([speed isEqualToString:@"fast"]) {
		[motionManager setDeviceMotionUpdateInterval:1.0/SENSOR_GAME_HZ];
	}
	else if([speed isEqualToString:@"fastest"]) {
		[motionManager setDeviceMotionUpdateInterval:1.0/SENSOR_FASTEST_HZ];
	}
	else {
		[PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown motion speed string: %@", speed]];
		return;
	}
	LogVerbose(@"Sensors: motion speed: %@", speed);
}

- (void)setMotionAutoUpdates:(BOOL)motionAutoUpdates {
	if(_motionAutoUpdates == motionAutoUpdates) {return;}
	_motionAutoUpdates = motionAutoUpdates;
	if(motionManager.deviceMotionActive) {
		[motionManager stopDeviceMotionUpdates];
		if(self.motionAutoUpdates) {
			[motionManager startDeviceMotionUpdatesToQueue:motionQueue
			                                   withHandler:^(CMDeviceMotion *data, NSError *error) {
				[self sendMotion:data];
			}];
		}
		else {
			[motionManager startDeviceMotionUpdates];
		}
	}
	LogVerbose(@"Sensors: motion updates: %d", (int)motionAutoUpdates);
}

- (void)sendMotion {
	if(motionManager.isDeviceMotionAvailable) {
		[self sendMotion:motionManager.deviceMotion];
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
		case kCLAuthorizationStatusAuthorizedWhenInUse:
		case kCLAuthorizationStatusAuthorizedAlways:
			statusString = @"authorized";
			break;
		default:
			statusString = @"not determined";
			break;
	}
	LogVerbose(@"Sensors: location authorization: %@", statusString);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	if(!hasIgnoredStartingLocation) { // ignore stale stored location when starting
		CLLocation *location = [locations objectAtIndex:0];
		if(fabs([location.timestamp timeIntervalSinceNow]) > 1.0) {
			hasIgnoredStartingLocation = YES;
			return; // assume there aren't any extra locations in the array
		}
	}
	if(self.locationAutoUpdates) {
		for(CLLocation *location in locations) { // handle locations, oldest is first
			[self sendLocation:location];
		}
	}
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
	LogVerbose(@"Sensors: location updates paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	LogVerbose(@"Sensors: location updates resumed");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	if(self.compassAutoUpdates) {
		[self sendCompass:newHeading];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	LogError(@"Sensors: location manager error: %@", error.localizedDescription);
}

#pragma mark Private

// reorient accel data to current orientation
- (void)sendAccel:(CMAccelerometerData *)accel {
	#ifdef DEBUG_SENSORS
		LogVerbose(@"accel %f %f %f",
			accel.acceleration.x, accel.acceleration.y, accel.acceleration.z);
	#endif
	float x = accel.acceleration.x;
	float y = accel.acceleration.y;
	float z = accel.acceleration.z;
	if(self.accelOrientation) {
		[self reorient:&x y:&y z:&z];
	}
	[PureData sendAccel:x y:y z:z];
	[self.osc sendAccel:x y:y z:z];
}

- (void)sendGyro:(CMGyroData *)gyro {
	#ifdef DEBUG_SENSORS
		LogVerbose(@"gyro %f %f %f", gyro.rotationRate.x, gyro.rotationRate.y, gyro.rotationRate.z);
	#endif
	[PureData sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
	[self.osc sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
}

- (void)sendLocation:(CLLocation *)location {
	#ifdef DEBUG_SENSORS
		LogVerbose(@"locate %@", location.description);
	#endif
	[PureData sendLocation:location.coordinate.latitude
	                   lon:location.coordinate.longitude
	              accuracy:location.horizontalAccuracy];
	[PureData sendSpeed:location.speed course:location.course];
	[PureData sendAltitude:location.altitude accuracy:location.verticalAccuracy];
	[self.osc sendLocation:location.coordinate.latitude
	                   lon:location.coordinate.longitude
	              accuracy:location.horizontalAccuracy];
	[self.osc sendSpeed:location.speed course:location.course];
	[self.osc sendAltitude:location.altitude accuracy:location.verticalAccuracy];
}

- (void)sendCompass:(CLHeading *)heading {
	#ifdef DEBUG_SENSORS
		LogVerbose(@"heading %@", heading.description);
	#endif
	[PureData sendCompass:heading.magneticHeading];
	[self.osc sendCompass:heading.magneticHeading];
}

- (void)sendMagnet:(CMMagnetometerData *)magnet {
	#ifdef DEBUG_SENSORS
		LogVerbose(@"magnet %f %f %f", magnet.magneticField.x, magnet.magneticField.y, magnet.magneticField.z);
	#endif
	[PureData sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
	[self.osc sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
}

/// oriented to reference frame already
- (void)sendMotion:(CMDeviceMotion *)motion {

	#ifdef DEBUG_SENSORS
		LogVerbose(@"motion attitude %f %f %f",
			motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw);
	#endif
	[PureData sendMotionAttitude:motion.attitude.pitch roll:motion.attitude.roll yaw:motion.attitude.yaw];
	[self.osc sendMotionAttitude:motion.attitude.pitch roll:motion.attitude.roll yaw:motion.attitude.yaw];

	#ifdef DEBUG_SENSORS
		LogVerbose(@"motion rotation %f %f %f",
			motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z);
	#endif
	[PureData sendMotionRotation:motion.rotationRate.x y:motion.rotationRate.y z:motion.rotationRate.z];
	[self.osc sendMotionRotation:motion.rotationRate.x y:motion.rotationRate.y z:motion.rotationRate.z];

	#ifdef DEBUG_SENSORS
		LogVerbose(@"motion gravity %f %f %f",
			motion.gravity.x, motion.gravity.y, motion.gravity.z);
	#endif
	[PureData sendMotionGravity:motion.gravity.x y:motion.gravity.y z:motion.gravity.z];
	[self.osc sendMotionGravity:motion.gravity.x y:motion.gravity.y z:motion.gravity.z];

	#ifdef DEBUG_SENSORS
		LogVerbose(@"motion user %f %f %f",
			motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
	#endif
	[PureData sendMotionUser:motion.userAcceleration.x y:motion.userAcceleration.y z:motion.userAcceleration.z];
	[self.osc sendMotionUser:motion.userAcceleration.x y:motion.userAcceleration.y z:motion.userAcceleration.z];
}

/// update location orientation based on current orientation
- (void)updateLocationOrientation {
	// faceup / facedown are ignored by location manager
	switch(self.currentOrientation) {
		case UIInterfaceOrientationPortrait:
			locationManager.headingOrientation = CLDeviceOrientationPortrait;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			locationManager.headingOrientation = CLDeviceOrientationPortraitUpsideDown;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			locationManager.headingOrientation = CLDeviceOrientationLandscapeLeft;
			break;
		case UIInterfaceOrientationLandscapeRight:
			locationManager.headingOrientation = CLDeviceOrientationLandscapeRight;
			break;
		default:
			break;
	}
}

/// reorient point to current orientation
/// nominal orientation is portrait: x - left/right, y - top/bottom
- (void)reorient:(float *)x y:(float *)y z:(float *)z {
	switch(self.currentOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationUnknown:
			break;
		case UIInterfaceOrientationLandscapeRight:
			(*x) = -(*y);
			(*y) = (*x);
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			(*x) = -(*x);
			(*y) = -(*y);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			(*x) = (*y);
			(*y) = -(*x);
			break;
	}
}

@end
