/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * References:
 * - https://www.raywenderlich.com/66532/ios-7-game-controller-tutorial
 * - http://iosdevelopertips.com/core-services/introduction-game-controllers-ios-7.html
 *
 */
#import <UIKit/UIKit.h>
#import <GameController/GameController.h>

@class Osc;

/// iOS GameController manager
@interface Controllers : NSObject

@property (weak, nonatomic) Osc *osc; //< pointer to osc instance
@property (assign, nonatomic) BOOL enabled; //< enable game controller support
@property (readonly, nonatomic) BOOL discovering; //< YES if currently discovering

/// currently connected controllers
@property (nonatomic) NSMutableArray *controllers;

/// start new controller discovery, not needed for previously connected controllers
- (void)startDiscovery;

/// stop new controller discovery, if it's enabled
- (void)stopDiscovery;

/// returns YES if game controller support is available on this device
+ (BOOL)controllersAvailable;

@end

/// iOS GameController wrapper
@interface Controller : NSObject

@property (readonly, nonatomic) NSString *name; //< unique name based on index+1 ie. "gc1"

@property (nonatomic) int index; //< current device index
@property (nonatomic) Controllers *parent; //< parent controllers object
@property (nonatomic) GCController *controller; //< base controller object

@end
