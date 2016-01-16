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

@class SceneManager;

/// iOS sensor manager, forwards events to pd
@interface Sensors : NSObject <UIAccelerometerDelegate, CLLocationManagerDelegate, PdSensorEventDelegate>

@property (weak, nonatomic) SceneManager *sceneManager; //< parent scene manager

@property (assign, nonatomic) BOOL enableAccel; // enable receiving accel events?
@property (assign, nonatomic) BOOL enableGyro; // enable receiving gyro events?
@property (assign, nonatomic) BOOL enableMagnet; // enable receiving magnetometer events?
@property (assign, nonatomic) BOOL enableLocation; // enable receiving location events?
@property (assign, nonatomic) BOOL enableHeading; // enable receiving heading events?

@property (assign, nonatomic) UIInterfaceOrientation currentOrientation; // accel orientation based on this

@end
