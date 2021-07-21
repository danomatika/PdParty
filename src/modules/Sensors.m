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
#import <Foundation/NSTimer.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSOperation.h>
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
	CMMotionManager *motionManager; //< for raw sensor data and processed quantities
    NSTimer* motionTimer;
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
	self.accelSpeed = @"fastest";
	self.gyroAutoUpdates = YES;
	self.gyroSpeed = @"fastest";
	self.locationAutoUpdates = YES;
	self.locationAccuracy = @"best";
	self.locationFilter = 0;
	self.compassAutoUpdates = YES;
	self.compassFilter = 1;
	self.magnetAutoUpdates = YES;
	self.magnetSpeed = @"fastest";
    
    self.processedMotionSpeed = @"fastest";
    self.processedMotionAutoUpdates = YES;
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
                [motionManager startGyroUpdates];
				/*[motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
					withHandler:^(CMGyroData *data, NSError *error) {
					[self sendGyro:data];
				}];*/
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

#pragma mark DeviceMotion

- (void)setProcessedMotionEnabled:(BOOL)processedMotionEnabled {
    if(self.processedMotionEnabled == processedMotionEnabled) {
        return;
    }
    _processedMotionEnabled = processedMotionEnabled;
    if(processedMotionEnabled)
    {
        if([motionManager isDeviceMotionAvailable])
        {
            if(self.processedMotionAutoUpdates)
            {
                //  NOTE - Assuming it's best practice for interactive applications to
                //get the data as it is available, instead of queueing it... (but the
                //raw sensor data - accel, gyro and magnet - are using queue mechanism)
                
                // Configure a timer to fetch the motion data.
                motionTimer = [[NSTimer alloc]
                                      initWithFireDate: [NSDate dateWithTimeIntervalSinceNow:0]
                                       interval: [motionManager deviceMotionUpdateInterval]
                                        repeats: true
                                          block: ^(NSTimer* timer)
                {
                    CMDeviceMotion* data = [self->motionManager deviceMotion];
                    if(data)
                    {
                        [self sendProcessedMotion:data];
                    }
                }
                ];
                
                // Add the timer to the current run loop.
                [NSRunLoop.currentRunLoop addTimer:motionTimer forMode: NSDefaultRunLoopMode];
            }
            else {
                [motionManager startDeviceMotionUpdates];
            }
            DDLogVerbose(@"Sensors: processed motion enabled");
        }
        else {
            DDLogWarn(@"Sensors: processed motion not available on this device");
        }
    }
    else { // stop
        if([motionManager isDeviceMotionActive]) {
            [motionManager stopDeviceMotionUpdates];
            DDLogVerbose(@"Sensors: processed motion disabled");
        }
    }
}

- (void)setProcessedMotionSpeed:(NSString *)speed {
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
        [PureData sendPrint:[NSString stringWithFormat:@"ignoring unknown deviceMotionUpdateInterval speed string: %@", speed]];
        return;
    }
    DDLogVerbose(@"Sensors: processedMotion speed: %@", speed);
}

- (void)setProcessedMotionAutoUpdates:(BOOL)processedMotionAutoUpdates
{
    if(_processedMotionAutoUpdates == processedMotionAutoUpdates) {return;}
    _processedMotionAutoUpdates = processedMotionAutoUpdates;
    if([motionManager isDeviceMotionActive]) {
        [motionManager stopDeviceMotionUpdates];
        if(self.processedMotionAutoUpdates) {
            //  NOTE - Assuming it's best practice for interactive applications to
            //get the data as it is available, instead of queueing it... (but the
            //raw sensor data - accel, gyro and magnet - are using queue mechanism)
            
            // Configure a timer to fetch the motion data.
            motionTimer = [[NSTimer alloc]
                                  initWithFireDate: [NSDate dateWithTimeIntervalSinceNow:0]
                                   interval: [motionManager deviceMotionUpdateInterval]
                                    repeats: true
                                      block: ^(NSTimer* timer)
            {
                CMDeviceMotion* data = [self->motionManager deviceMotion];
                if(data)
                {
                    [self sendProcessedMotion:data];
                }
            }
            ];
            
            // Add the timer to the current run loop.
            [NSRunLoop.currentRunLoop addTimer:motionTimer forMode: NSDefaultRunLoopMode];
        }
        else {
            [motionManager startDeviceMotionUpdates];
        }
    }
    DDLogVerbose(@"Sensors: processedMotion auto updates: %d", (int)processedMotionAutoUpdates);
}

- (void)sendProcessedMotion {
 if(motionManager.isDeviceMotionActive) {
     [self sendProcessedMotion:motionManager.deviceMotion];
 }
}

- (void)sendOrientationEuler {
    if(motionManager.isDeviceMotionActive) {
        [self sendOrientationEuler:motionManager.deviceMotion.attitude];
    }
}
- (void)sendOrientationQuat {
    if(motionManager.isDeviceMotionActive) {
        [self sendOrientationQuat:motionManager.deviceMotion.attitude];
    }
}
- (void)sendOrientationMatrix {
    if(motionManager.isDeviceMotionActive) {
        [self sendOrientationMatrix:motionManager.deviceMotion.attitude];
    }
}
- (void)sendRotationRate {
    if(motionManager.isDeviceMotionActive) {
        [self sendRotationRate:motionManager.deviceMotion];
    }
}
- (void)sendGravity {
    if(motionManager.isDeviceMotionActive) {
        [self sendGravity:motionManager.deviceMotion];
    }
}
- (void)sendUserAcceleration {
    if(motionManager.isDeviceMotionActive) {
        [self sendUserAcceleration:motionManager.deviceMotion];
    }
}

- (void)setOrientationEulerEnabled:(BOOL)enabled {
    _orientationEulerEnabled = enabled;
}

- (void)setOrientationQuatEnabled:(BOOL)enabled {
    _orientationQuatEnabled = enabled;
}

- (void)setOrientationMatrixEnabled:(BOOL)enabled {
    _orientationMatrixEnabled = enabled;
}

- (void)setUserAccelerationEnabled:(BOOL)enabled {
    _userAccelerationEnabled = enabled;
}

- (void)setGravityEnabled:(BOOL)enabled {
    _gravityEnabled = enabled;
}

- (void)setRotationRateEnabled:(BOOL)enabled {
    _rotationRateEnabled = enabled;
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
	#ifdef DEBUG_SENSORS
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
	#ifdef DEBUG_SENSORS
		DDLogVerbose(@"gyro %f %f %f", gyro.rotationRate.x, gyro.rotationRate.y, gyro.rotationRate.z);
	#endif
	[PureData sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
	[self.osc sendGyro:gyro.rotationRate.x y:gyro.rotationRate.y z:gyro.rotationRate.z];
}

- (void)sendLocation:(CLLocation *)location {
	#ifdef DEBUG_SENSORS
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
	#ifdef DEBUG_SENSORS
		DDLogVerbose(@"heading %@", heading.description);
	#endif
	[PureData sendCompass:heading.magneticHeading];
	[self.osc sendCompass:heading.magneticHeading];
}

- (void)sendMagnet:(CMMagnetometerData *)magnet {
	#ifdef DEBUG_SENSORS
		DDLogVerbose(@"magnet %f %f %f", magnet.magneticField.x, magnet.magneticField.y, magnet.magneticField.z);
	#endif
	[PureData sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
	[self.osc sendMagnet:magnet.magneticField.x y:magnet.magneticField.y z:magnet.magneticField.z];
}

- (void)sendProcessedMotion:(CMDeviceMotion *)processedMotion
{
    if(self.orientationEulerEnabled) {
        [self sendOrientationEuler:processedMotion.attitude];
    }
    if(self.orientationQuatEnabled) {
        [self sendOrientationQuat:processedMotion.attitude];
    }
    if(self.orientationMatrixEnabled) {
        [self sendOrientationMatrix:processedMotion.attitude];
    }
    if(self.rotationRateEnabled) {
        [self sendRotationRate:processedMotion];
    }
    if(self.gravityEnabled) {
        [self sendGravity:processedMotion];
    }
    if(self.userAccelerationEnabled) {
        [self sendUserAcceleration:processedMotion];
    }
}
             
- (void)sendOrientationEuler:(CMAttitude *)attitude {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"orientationEuler (yaw, pitch, roll) %f %f %f", attitude.yaw, attitude.pitch, attitude.roll);
    #endif
    [PureData sendOrientationEuler:attitude.yaw pitch:attitude.pitch roll:attitude.roll];
    [self.osc sendOrientationEuler:attitude.yaw pitch:attitude.pitch roll:attitude.roll];
}

- (void)sendOrientationQuat:(CMAttitude *)attitude {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"orientationQuat (x, y, z, w) %f %f %f %f", attitude.quaternion.x, attitude.quaternion.y, attitude.quaternion.z, attitude.quaternion.w);
    #endif
    [PureData sendOrientationQuat: attitude.quaternion.x y:attitude.quaternion.y z:attitude.quaternion.z w:attitude.quaternion.w];
    [self.osc sendOrientationQuat: attitude.quaternion.x y:attitude.quaternion.y z:attitude.quaternion.z w:attitude.quaternion.w];
}

- (void)sendOrientationMatrix:(CMAttitude *)attitude {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"orientationMatrix (m11 m12 m13 m21 m22 m23 m31 m32 m33) %f %f %f %f %f %f %f %f %f",
            attitude.rotationMatrix.m11, attitude.rotationMatrix.m12, attitude.rotationMatrix.m13, attitude.rotationMatrix.m21, attitude.rotationMatrix.m22, attitude.rotationMatrix.m23, attitude.rotationMatrix.m31, attitude.rotationMatrix.m32, attitude.rotationMatrix.m33);
    #endif
    [PureData sendOrientationQuat: attitude.quaternion.x y:attitude.quaternion.y z:attitude.quaternion.z w:attitude.quaternion.w];
    [self.osc sendOrientationQuat: attitude.quaternion.x y:attitude.quaternion.y z:attitude.quaternion.z w:attitude.quaternion.w];
}

- (void)sendRotationRate:(CMDeviceMotion *)deviceMotion {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"rotationRate %f %f %f", deviceMotion.rotationRate.x, deviceMotion.rotationRate.y, deviceMotion.rotationRate.z);
    #endif
    [PureData sendRotationRate: deviceMotion.rotationRate.x y:deviceMotion.rotationRate.y z:deviceMotion.rotationRate.z];
    [self.osc sendRotationRate: deviceMotion.rotationRate.x y:deviceMotion.rotationRate.y z:deviceMotion.rotationRate.z];
}

- (void)sendGravity:(CMDeviceMotion *)deviceMotion {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"gravity %f %f %f", deviceMotion.gravity.x, deviceMotion.gravity.y, deviceMotion.gravity.z);
    #endif
    [PureData sendGravity: deviceMotion.gravity.x y:deviceMotion.gravity.y z:deviceMotion.gravity.z];
    [self.osc sendGravity: deviceMotion.gravity.x y:deviceMotion.gravity.y z:deviceMotion.gravity.z];
}

- (void)sendUserAcceleration:(CMDeviceMotion *)deviceMotion {
    #ifdef DEBUG_SENSORS
        DDLogVerbose(@"userAccel %f %f %f", deviceMotion.userAcceleration.x, deviceMotion.userAcceleration.y, deviceMotion.userAcceleration.z);
    #endif
    [PureData sendUserAcceleration: deviceMotion.userAcceleration.x y:deviceMotion.userAcceleration.y z:deviceMotion.userAcceleration.z];
    [self.osc sendUserAcceleration: deviceMotion.userAcceleration.x y:deviceMotion.userAcceleration.y z:deviceMotion.userAcceleration.z];
}

@end
