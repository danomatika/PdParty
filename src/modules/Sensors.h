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

/// set location (and optionally accel) orientation relative to the interface
/// default portrait, ex. patch top +y axis regardless of rotation
@property (assign, nonatomic) UIInterfaceOrientation currentOrientation;

/// reset sensors back to default values
- (void)reset;

#pragma mark Extended Touch

/// enable extended touch?
@property (assign, nonatomic) BOOL extendedTouchEnabled;

#pragma mark Accel

/// enable accelerometer service?
@property (assign, nonatomic) BOOL accelEnabled;

/// accel update speed: "slow", "normal", "fast", or "fastest" (default: "normal")
@property (nonatomic) NSString *accelSpeed;

/// set accel orientation relative to the interface? (default: NO)
/// ex. patch top +y axis regardless of rotation
@property (assign, nonatomic) BOOL accelOrientation;

#pragma mark Gyro

/// enable gyro service?
@property (assign, nonatomic) BOOL gyroEnabled;

/// set to NO if sending manually (default: YES)
@property (assign, nonatomic) BOOL gyroAutoUpdates;

/// gyro update speed: "slow", "normal", "fast", or "fastest" (default: "normal")
@property (nonatomic) NSString *gyroSpeed;

/// request current gyro values manually, use this when auto updates is NO
- (void)sendGyro;

#pragma mark Location

/// enable location service? includes speed & course events
@property (assign, nonatomic) BOOL locationEnabled;

/// set to NO if sending manually (default: YES)
@property (assign, nonatomic) BOOL locationAutoUpdates;

/// desired location accuracy: "3km", "1km", "100m", "10m", "best", "navigation" (default: "best")
@property (nonatomic) NSString *locationAccuracy;

/// location distance filter in meters (default: 0)
@property (nonatomic) float locationFilter;

/// request current location manually, use this when auto updates is NO
- (void)sendLocation;

#pragma mark Compass

/// enable compass service?
@property (assign, nonatomic) BOOL compassEnabled;

/// set to NO if sending manually (default: YES)
@property (assign, nonatomic) BOOL compassAutoUpdates;

/// compass filter in degrees (default: 1)
@property (nonatomic) float compassFilter;

/// request current compass value manually, use this when auto updates is NO
- (void)sendCompass;

#pragma mark Magnet

/// enable magnet service?
@property (assign, nonatomic) BOOL magnetEnabled;

/// set to NO if sending manually (default: YES)
@property (assign, nonatomic) BOOL magnetAutoUpdates;

/// magnet update speed: "slow", "normal", "fast", or "fastest" (default: "normal")
@property (nonatomic) NSString *magnetSpeed;

/// request current gyro value manually, use this when auto updates is NO
- (void)sendMagnet;

#pragma mark Motion

// process motion: attitude, rotation rate, gravity accel, and user accel relative to a reference frame

/// enabled process motion service
@property (assign, nonatomic) BOOL motionEnabled;

/// set to NO if sending manually (default: YES)
@property (assign, nonatomic) BOOL motionAutoUpdates;

/// process motion update speed: "slow", "normal", "fast", or "fastest" (default: "normal")
@property (nonatomic) NSString *motionSpeed;

/// request current motion values manually, use this when auto updates is NO
- (void)sendMotion;

@end
