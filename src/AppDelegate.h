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
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@class PureData;
@class Midi;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// global access
@property (nonatomic, strong) PureData *pureData;
@property (nonatomic, strong) Midi *midi;

@property (nonatomic, strong) CMMotionManager *motionManager; // for accel data

@end
