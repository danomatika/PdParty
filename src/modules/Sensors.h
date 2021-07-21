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
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class Osc;

/// iOS sensor manager, forwards events to pd & osc
@interface Sensors : NSObject <CLLocationManagerDelegate>

@property (weak, nonatomic) Osc *osc; //< pointer to osc instance
@property (assign, nonatomic) UIInterfaceOrientation currentOrientation; //< accel orientation based on this

/// reset sensors back to default values
- (void)reset;

#pragma mark Accel

@property (assign, nonatomic) BOOL accelEnabled; //< enable accelerometer service
@property (nonatomic) NSString *accelSpeed; //< accel update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

#pragma mark Gyro

@property (assign, nonatomic) BOOL gyroEnabled; //< enable gyro service
@property (assign, nonatomic) BOOL gyroAutoUpdates; //< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *gyroSpeed;  //< gyro update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

- (void)sendGyro; //< request current gyro values manually, use this when auto updates is NO

#pragma mark Location

@property (assign, nonatomic) BOOL locationEnabled; //< enable location service, includes speed & course events
@property (assign, nonatomic) BOOL locationAutoUpdates; //< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *locationAccuracy; //< desired location accuracy: "3km", "1km", "100m", "10m", "best", "navigation" (default: "best")
@property (nonatomic) float locationFilter; //< location distance filter in meters (default: 0)

- (void)sendLocation; //< request current location manually, use this when auto updates is NO

#pragma mark Compass

@property (assign, nonatomic) BOOL compassEnabled; //< enable compass service
@property (assign, nonatomic) BOOL compassAutoUpdates; //< set to NO if sending manually (default: YES)
@property (nonatomic) float compassFilter; //< compass filter in degrees (default: 1)

- (void)sendCompass; //< request current compass value manually, use this when auto updates is NO

#pragma mark Magnet

@property (assign, nonatomic) BOOL magnetEnabled; //< enable magnet service
@property (assign, nonatomic) BOOL magnetAutoUpdates; //< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *magnetSpeed; //< magnet update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

- (void)sendMagnet; //< request current magnet value manually, use this when auto updates is NO

#pragma mark ProcessedMotion

//  "Raw accelerometer and gyroscope data must be processed to remove bias
//from other factors, such as gravity. The device-motion service does this
//processing for you, giving you refined data" - https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data?language=objc

@property (assign, nonatomic) BOOL processedMotionEnabled; //< enable new motion data from processed sensor data
@property (assign, nonatomic) BOOL processedMotionAutoUpdates;//< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *processedMotionSpeed; //< processed motion update speed: "slow", "normal", "fast", or "fastest" (default: "normal")
- (void)sendProcessedMotion; //< request current orientation, rotation rate, gravity, user acceleration manually. Use this when processed motion auto updates is NO

#pragma mark OrientationEuler

@property (assign, nonatomic) BOOL orientationEulerEnabled;
/*@property (assign, nonatomic) BOOL orientationEulerAutoUpdates;
@property (nonatomic) NSString *orientationEulerSpeed;*/
- (void)sendOrientationEuler; //< request current orientationEuler value manually, use this when processed motion auto updates is NO

#pragma mark OrientationQuat

@property (assign, nonatomic) BOOL orientationQuatEnabled;
/*@property (assign, nonatomic) BOOL orientationQuatAutoUpdates;
@property (nonatomic) NSString *orientationQuatSpeed;*/
- (void)sendOrientationQuat; //< request current orientationQuat value manually, use this when processed motion auto updates is NO

#pragma mark OrientationMatrix

@property (assign, nonatomic) BOOL orientationMatrixEnabled;
/*@property (assign, nonatomic) BOOL orientationMatrixAutoUpdates;
@property (nonatomic) NSString *orientationMatrixSpeed;*/
- (void)sendOrientationMatrix; //< request current orientationMatrix value manually, use this when processed motion auto updates is NO

#pragma mark RotationRate

@property (assign, nonatomic) BOOL rotationRateEnabled;
/*@property (assign, nonatomic) BOOL rotationRateAutoUpdates;
@property (nonatomic) NSString *rotationRateSpeed;*/
- (void)sendRotationRate; //< request current rotationrate value manually, use this when processed motion auto updates is NO

#pragma mark Gravity

@property (assign, nonatomic) BOOL gravityEnabled;
/*@property (assign, nonatomic) BOOL gravityAutoUpdates;
@property (nonatomic) NSString *gravitySpeed;*/
- (void)sendGravity; //< request current gravity value manually, use this when processed motion auto updates is NO

#pragma mark UserAcceleration

@property (assign, nonatomic) BOOL userAccelerationEnabled;
/*@property (assign, nonatomic) BOOL userAccelerationAutoUpdates;
@property (nonatomic) NSString *userAccelerationSpeed;*/
- (void)sendUserAcceleration; //< request current userAcceleration value manually, use this when processed motion auto updates is NO

@end
