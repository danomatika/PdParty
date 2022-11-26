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

@property (weak, nonatomic) Osc *osc; ///< pointer to osc instance
@property (assign, nonatomic) UIInterfaceOrientation currentOrientation; ///< accel orientation based on this

/// reset sensors back to default values
- (void)reset;

#pragma mark Accel

@property (assign, nonatomic) BOOL accelEnabled; ///< enable accelerometer service
@property (nonatomic) NSString *accelSpeed; ///< accel update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

#pragma mark Gyro

@property (assign, nonatomic) BOOL gyroEnabled; ///< enable gyro service
@property (assign, nonatomic) BOOL gyroAutoUpdates; ///< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *gyroSpeed;  ///< gyro update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

- (void)sendGyro; ///< request current gyro values manually, use this when auto updates is NO

#pragma mark Location

@property (assign, nonatomic) BOOL locationEnabled; ///< enable location service, includes speed & course events
@property (assign, nonatomic) BOOL locationAutoUpdates; ///< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *locationAccuracy; ///< desired location accuracy: "3km", "1km", "100m", "10m", "best", "navigation" (default: "best")
@property (nonatomic) float locationFilter; ///< location distance filter in meters (default: 0)

- (void)sendLocation; ///< request current location manually, use this when auto updates is NO

#pragma mark Compass

@property (assign, nonatomic) BOOL compassEnabled; ///< enable compass service
@property (assign, nonatomic) BOOL compassAutoUpdates; ///< set to NO if sending manually (default: YES)
@property (nonatomic) float compassFilter; ///< compass filter in degrees (default: 1)

- (void)sendCompass; ///< request current compass value manually, use this when auto updates is NO

#pragma mark Magnet

@property (assign, nonatomic) BOOL magnetEnabled; ///< enable magnet service
@property (assign, nonatomic) BOOL magnetAutoUpdates; ///< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *magnetSpeed; ///< magnet update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

- (void)sendMagnet; ///< request current gyro value manually, use this when auto updates is NO

#pragma mark Motion

// process motion: attitude, rotation rate, gravity accel, and user accel relative to a reference frame

@property (assign, nonatomic) BOOL motionEnabled; ///< enabled process motion service
@property (assign, nonatomic) BOOL motionAutoUpdates; ///< set to NO if sending manually (default: YES)
@property (nonatomic) NSString *motionSpeed; ///< process motion update speed: "slow", "normal", "fast", or "fastest" (default: "normal")

- (void)sendMotion; ///< request current motion values manually, use this when auto updates is NO

@end
