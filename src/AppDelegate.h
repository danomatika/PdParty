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

#import "PureData.h"
#import "Midi.h"
#import "Osc.h"

@class PatchViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// global access
@property (strong, nonatomic) PureData *pureData;
@property (strong, nonatomic) Midi *midi;
@property (strong, nonatomic) Osc *osc;

@property (strong, nonatomic) CMMotionManager *motionManager; // for accel data

@end
