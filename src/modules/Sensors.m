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
	CMMotionManager *motionManager; //< for accel data
	CLLocationManager *locationManager; //< for location data
	BOOL hasIgnoredStartingLocation; //< ignore the initial, old location
}
@end

@implementation Sensors

- (id)init {
	self = [super init];
	if(self) {
		
		// init motion manager
		motionManager = [[CMMotionManager alloc] init];
		
		// current UI orientation for accel
		if(Util.isDeviceATablet) { // iPad can started rotated
			self.currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
		else { // do not start rotated on iPhone
			self.currentOrientation = UIInterfaceOrientationPortrait;
		}
		
		// init location manager
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
	
		[self reset];
	}
	return self;
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
	_currentOrientation = currentOrientation;
	// TODO: currently doesn't handle faceup / facedown UIDeviceOrientations?
	switch(currentOrientation) {
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

- (void)reset {
	self.accelSpeed = @"normal";
	self.gyroAutoUpdates = YES;
	self.gyroSpeed = @"normal";
	self.locationAutoUpdates = YES;
	self.locationAccuracy = @"best";
	self.locationFilter = 0;
	self.compassAutoUpdates = YES;
	self.compassFilter = 1;
	self.magnetAutoUpdates = YES;
	self.magnetSpeed = @"normal";
}

#pragma mark Accel

- (void)setAccelEnabled:(BOOL)accelEnabled {
	if(self.accelEnabled == accelEnabled) {
		return;
	}
	_accelEnabled = accelEnabled;
	if(accelEnabled) { // start
		if([motionManager isAccelerometerAvailable]) {
			[motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
					[self sendAccel:accelerometerData];
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
	DDLogVerbose(@"Sensors: accel speed: %@", speed);
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
				[motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
					withHandler:^(CMGyroData *data, NSError *error) {
					[self sendGyro:data];
				}];
			}
			else {
				[motionManager startGyroUpdates];
			}
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
	DDLogVerbose(@"Sensors: gyro speed: %@", speed);
}

- (void)setGyroAutoUpdates:(BOOL)gyroAutoUpdates {
	if(_gyroAutoUpdates == gyroAutoUpdates) {return;}
	_gyroAutoUpdates = gyroAutoUpdates;
	if(motionManager.gyroActive) {
		[motionManager stopGyroUpdates];
		if(self.gyroAutoUpdates) {
			[motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMGyroData *data, NSError *error) {
				[self sendGyro:data];
			}];
		}
		else {
			[motionManager startGyroUpdates];
		}
	}
	DDLogVerbose(@"Sensors: gyro updates: %d", (int)gyroAutoUpdates);
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
				[locationManager startUpdatingLocation];
				[PureData sendPrint:@"location enabled"];
				if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
					[locationManager requestAlwaysAuthorization];
				}
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
		DDLogVerbose(@"Sensors: compass filter: +/- %f", degrees);
	}
	else { // clip 0 & negative values
		locationManager.headingFilter = kCLHeadingFilterNone;
		DDLogVerbose(@"Sensors: compass filter: none");
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
				[motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue]
					withHandler:^(CMMagnetometerData *data, NSError *error) {
					[self sendMagnet:data];
				}];
			}
			else {
				[motionManager startMagnetometerUpdates];
			}
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
	DDLogVerbose(@"Sensors: magnet speed: %@", speed);
}

- (void)setMagnetAutoUpdates:(BOOL)magnetAutoUpdates {
	if(_magnetAutoUpdates == magnetAutoUpdates) {return;}
	_magnetAutoUpdates = magnetAutoUpdates;
	if(motionManager.magnetometerActive) {
		[motionManager stopMagnetometerUpdates];
		if(self.magnetAutoUpdates) {
			[motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue]
				withHandler:^(CMMagnetometerData *data, NSError *error) {
				[self sendMagnet:data];
			}];
		}
		else {
			[motionManager startMagnetometerUpdates];
		}
	}
	DDLogVerbose(@"Sensors: magnet updates: %d", (int)magnetAutoUpdates);
}

- (void)sendMagnet {
	if(motionManager.magnetometerActive) {
		[self sendMagnet:motionManager.magnetometerData];
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
	DDLogVerbose(@"Sensors: location authorization: %@", statusString);
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
	DDLogVerbose(@"Sensors: location updates paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	DDLogVerbose(@"Sensors: location updates resumed");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	if(self.compassAutoUpdates) {
		[self sendCompass:newHeading];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	DDLogError(@"Sensors: location manager error: %@", error.localizedDescription);
}

#pragma mark Private

// orient accel data to current orientation
- (void)sendAccel:(CMAccelerometerData *)accel {
	#ifdef DEBUG_CONTROLLERS
		DDLogVerbose(@"accel %f %f %f", accel.acceleration.x,
										accel.acceleration.y,
										accel.acceleration.z);
	#endif
	switch(self.currentOrientation) {
		case UIInterfaceOrientationPortrait:
			[PureData sendAccel:accel.acceleration.x
							  y:accel.acceleration.y
							  z:accel.acceleration.z];
			[self.osc sendAccel:accel.acceleration.x
			                  y:accel.acceleration.y
			                  z:accel.acceleration.z];
			break;
		case UIInterfaceOrientationLandscapeRight:
			[PureData sendAccel:-accel.acceleration.y
							  y:accel.acceleration.x
							  z:accel.acceleration.z];
			[self.osc sendAccel:-accel.acceleration.y
			                  y:accel.acceleration.x
			                  z:accel.acceleration.z];
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			[PureData sendAccel:-accel.acceleration.x
							  y:-accel.acceleration.y
							  z:accel.acceleration.z];
			[self.osc sendAccel:-accel.acceleration.x
			                  y:-accel.acceleration.y
			                  z:accel.acceleration.z];
			break;
		case UIInterfaceOrientationLandscapeLeft:
			[PureData sendAccel:accel.acceleration.y
							  y:-accel.acceleration.x
							  z:accel.acceleration.z];
			[self.osc sendAccel:accel.acceleration.y
			                  y:-accel.acceleration.x
			                  z:accel.acceleration.z];
			break;
		case UIInterfaceOrientationUnknown:
			break;
	}
}

- (void)sendGyro:(CMGyroData *)gyro {
	#ifdef DEBUG_CONTROLLERS
		DDLogVerbose(@"gyro %f %f %f", gyro.rotationRate.x, gyro.rotationRate.y, gyro.rotationRate.z);
	#endif
	[PureData sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
	[self.osc sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
}

- (void)sendLocation:(CLLocation *)location {
	#ifdef DEBUG_CONTROLLERS
		DDLogVerbose(@"locate %@", location.description);
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
	#ifdef DEBUG_CONTROLLERS
		DDLogVerbose(@"heading %@", heading.description);
	#endif
	[PureData sendCompass:heading.magneticHeading];
	[self.osc sendCompass:heading.magneticHeading];
}

- (void)sendMagnet:(CMMagnetometerData *)magnet {
	#ifdef DEBUG_CONTROLLERS
		DDLogVerbose(@"magnet %f %f %f", magnet.magneticField.x, magnet.magneticField.y, magnet.magneticField.z);
	#endif
	[PureData sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
	[self.osc sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
}

@end
