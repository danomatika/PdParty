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
@class Controller;

/// iOS GameController manager
@interface Controllers : NSObject

@property (weak, nonatomic) Osc *osc; ///< pointer to osc instance
@property (assign, nonatomic) BOOL enabled; ///< enable game controller support
@property (readonly, nonatomic) BOOL discovering; ///< YES if currently discovering

/// currently connected controllers
@property (nonatomic) NSMutableArray *controllers;

/// optional controller mappings array containing dictionarys with the following keys
/// * name: string, device name to match
/// * index: int, player index 1-4
/// * address: string, send address, alphanumeric chars only
/// * color: array, 0-255 RGB color value: [red, green, blue}, ex. [255, 0, 0]
/// ex. {"name" : "DualSense Wireless Controller", "index" : 2} ->
///     events sent to #controller gc2", player led index 2
/// ex. {"name" : "DualSense Wireless Controller", "address" : "pad", index : 2} ->
///     events sent to #controller pad, player led index 2
@property (nonatomic) NSArray *mappings;

/// start new controller discovery, not needed for previously connected controllers
- (void)startDiscovery;

/// stop new controller discovery, if it's enabled
- (void)stopDiscovery;

/// update the currently connected controllers
/// register any new ones and remove any that are no longer connected
- (void)updateConnectedControllers;

/// get controller by index
/// returns controller on success or nil on failure
- (Controller *)controllerAtIndex:(NSUInteger)index;

/// get controller by name, ie. "gc1", "gc2", "gc3", or "gc4"
/// returns controller on success or nil on failure
- (Controller *)controllerWithName:(NSString *)name;

/// get controller query info:
/// index, name, buttons, axes, touchpads, sensors, rumble?, led?
- (NSArray *)query;

/// returns YES if game controller support is available on this device
+ (BOOL)controllersAvailable;

@end

/// iOS GameController wrapper
@interface Controller : NSObject

@property (nonatomic) NSString *name; ///< unique name based on index+1 ie. "gc1"

@property (nonatomic) int index; ///< current device index
@property (nonatomic) Controllers *parent; ///< parent controllers object
@property (nonatomic) GCController *controller; ///< base controller object
@property (nonatomic) BOOL sensorsEnabled; ///< enable motion sensors? (if available)
@property (nonatomic) BOOL nativeSensors; ///< native sensor values and orientation?

/// set LED color (if supported by the device)
/// color range is 0-255
- (void)setColorRed:(float)red green:(float)green blue:(float)blue;

/// rumble at strength % 0-1 for duration ms
/// ex. 75% for half a second: rumble(0.75, 500)
/// rumble at 0% to stop
- (void)rumbleAtStrength:(float)percent duration:(unsigned int)ms;

/// get query info: index, name, buttons, axes, touchpads, sensors, rumble?, led?
- (NSArray *)query;

@end
