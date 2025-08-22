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
#import "Controllers.h"

#import "PureData.h"
#import "Osc.h"
#import "Util.h"
#import "Log.h"

#import "CoreHaptics/CoreHaptics.h"

// borrowed from SDL
#define SDL_STANDARD_GRAVITY 9.80665f

//#define DEBUG_CONTROLLERS

@implementation Controllers

- (id)init {
	self = [super init];
	if(self) {
		self.controllers = [NSMutableArray array];
	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self
	                                              name:GCControllerDidConnectNotification
	                                            object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self
	                                              name:GCControllerDidDisconnectNotification
	                                            object:nil];
	[self disconnectAll:YES];
}

- (void)startDiscovery {
	_discovering = YES;
	[GCController startWirelessControllerDiscoveryWithCompletionHandler: ^(void) {
		self->_discovering = NO;
		LogVerbose(@"Controllers: discovery timed out");
	}];
	LogVerbose(@"Controllers: discovery enabled");
}

- (void)stopDiscovery {
	if(self.discovering) {
		[GCController stopWirelessControllerDiscovery];
		LogVerbose(@"Controllers: discovery disabled");
	}
}

- (void)updateConnectedControllers {
	LogVerbose(@"Controllers: updating");
	
	// build array of currently known controllers
	NSMutableArray *known = [NSMutableArray array];
	for(Controller *c in self.controllers) {
		[known addObject:c.controller];
	}
	
	// compare with existing controllers
	NSMutableArray *current = [NSMutableArray arrayWithArray:[GCController controllers]];
	for(GCController *c in current) {
	
		// we know about this one
		if([known containsObject:c]) {
			[known removeObject:c];
		}
		else { // if a controller is not known, connect to it
			LogVerbose(@"Controllers: found new controller");
			[self connect:c];
		}
	}
	
	// anything left over can be removed
	for(GCController *c in known) {
		LogVerbose(@"Controllers: disconnecting stale controller");
		[self disconnect:c unset:NO];
	}
}

- (Controller *)controllerAtIndex:(NSUInteger)index {
	if(index < 0 || index >= self.controllers.count) {return nil;}
	return self.controllers[index];
}

- (Controller *)controllerWithName:(NSString *)name {
	for(Controller *c in self.controllers) {
		if([c.name isEqualToString:name]) {
			return c;
		}
	}
	return nil;
}

- (NSArray *)query {
	NSMutableArray *array = [NSMutableArray array];
	for(NSUInteger i = 0; i < self.controllers.count; i++) {
		Controller *controller = self.controllers[i];
		[array addObject:[controller query]];
	}
	return array;
}

+ (BOOL)controllersAvailable {
	return Util.deviceOSVersion >= 7.0;
}

#pragma mark GC Notifications

- (void)controllerDidConnect:(NSNotification *)notification {
	[self connect:(GCController *)[notification object]];
}

- (void)controllerDidDisconnect:(NSNotification *)notification {
	[self disconnect:(GCController *)[notification object] unset:NO];
}

#pragma mark Overridden Getters/Setters

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
	if(enabled) {
		[NSNotificationCenter.defaultCenter addObserver:self
		                                       selector:@selector(controllerDidConnect:)
		                                           name:GCControllerDidConnectNotification
		                                         object:nil];
		[NSNotificationCenter.defaultCenter addObserver:self
		                                       selector:@selector(controllerDidDisconnect:)
		                                           name:GCControllerDidDisconnectNotification
		                                         object:nil];
		LogVerbose(@"Controllers: enabled");
		[self updateConnectedControllers];
	}
	else {
		[self disconnectAll:YES];
		[NSNotificationCenter.defaultCenter removeObserver:self
		                                              name:GCControllerDidConnectNotification
		                                            object:nil];
		[NSNotificationCenter.defaultCenter removeObserver:self
		                                              name:GCControllerDidDisconnectNotification
		                                            object:nil];
		LogVerbose(@"Controllers: disabled");
	}
}

#pragma mark Private

// set up connection for a CGController, sends connection event
- (void)connect:(GCController *)controller {
	Controller *c = [[Controller alloc] init];
	c.parent = self;
	c.controller = controller;
	c.index = [self firstAvailableIndex];
	[self.controllers addObject:c];
	[self sortControllers];
	[PureData sendEvent:@"connect" forController:c.name];
	[self.osc sendEvent:@"connect" forController:c.name];
	if(controller.vendorName) {
		LogVerbose(@"Controllers: connected %@ (%@)", c.name, controller.vendorName);
	}
	else {
		LogVerbose(@"Controllers: connected %@", c.name);
	}
}

// sends disconnect event
// set unset:YES to unset the playerIndex led, do not do this from
// the disconnect callback or there will be a bad access error
- (void)disconnect:(GCController *)controller unset:(BOOL)unset {
	NSString *name;
	for(Controller *c in self.controllers) {
		if(c.controller == controller) {
			name = c.name;
			[self.controllers removeObject:c];
			break;
		}
	}
	if(unset) {
		controller.playerIndex = -1; // GCControllerPlayerIndexUnset
	}
	[PureData sendEvent:@"disconnect" forController:name];
	[self.osc sendEvent:@"disconnect" forController:name];
	if(controller.vendorName) {
		LogVerbose(@"Controllers: disconnected %@ (%@)", name, controller.vendorName);
	}
	else {
		LogVerbose(@"Controllers: disconnected %@", name);
	}
}

// disconnect all connected devices
- (void)disconnectAll:(BOOL)unset {
	for(Controller *c in self.controllers) {
		[self disconnect:c.controller unset:unset];
	}
	[self.controllers removeAllObjects];
}

// returns first available index, assumes array is sorted via controller index
- (int)firstAvailableIndex {
	for(int i = 0; i < self.controllers.count; ++i) {
		Controller *c = self.controllers[i];
		if(i != c.index) {
			return i;
		}
	}
	return (int)self.controllers.count;
}

// sort ascending
- (void)sortControllers {
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
	[self.controllers sortedArrayUsingDescriptors:@[sortDescriptor]];
}

@end

#pragma mark -

// touchpad state object for use in NSArray
@interface ControllerTouchpadState : NSObject {
@public
	BOOL pressed;
	float x;
	float y;
}
@end

@implementation ControllerTouchpadState
@end

#pragma mark -

// haptics handling adapted from SDL3: src/joystick/apple/SDL_mfijoystick.m

@interface ControllerRumbleMotor : NSObject
@property(nonatomic, strong) CHHapticEngine *engine API_AVAILABLE(ios(14.0));
@property(nonatomic, strong) id<CHHapticPatternPlayer> player API_AVAILABLE(ios(14.0));
@property BOOL active;
@end

@implementation ControllerRumbleMotor

- (void)dealloc {
	if(@available(iOS 14.0, *)) {
		if(self.player) {
			[self.player cancelAndReturnError:nil];
			self.player = nil;
		}
		if(self.engine) {
			[self.engine stopWithCompletionHandler:nil];
			self.engine = nil;
		}
	}
}

- (instancetype)initWithController:(GCController *)controller locality:(GCHapticsLocality)locality API_AVAILABLE(ios(14.0)) {
	self = [super init];
	if(self) {
		self.engine = [controller.haptics createEngineWithLocality:locality];
		if(self.engine == nil) {
			LogError(@"Controller: could not create haptics engine");
			return nil;
		}
		NSError *error;
		[self.engine startAndReturnError:&error];
		if(error != nil) {
			LogError(@"Controller: could not start haptics engine");
			return nil;
		}
		__weak ControllerRumbleMotor *weakSelf = self;
		self.engine.stoppedHandler = ^(CHHapticEngineStoppedReason stoppedReason) {
			if(weakSelf) {
				weakSelf.player = nil;
				weakSelf.engine = nil;
			}
		};
		self.engine.resetHandler = ^{
			if(weakSelf) {
				weakSelf.player = nil;
				[weakSelf.engine startAndReturnError:nil];
			}
		};
	}
	return self;
}

// ref: https://developer.apple.com/documentation/corehaptics/playing-a-single-tap-haptic-pattern?language=objc
- (BOOL)setIntensity:(float)intensity {
	if(@available(iOS 14.0, *)) {
		NSError *error = nil;
		if(self.engine == nil) {
			LogError(@"Controller: haptics engine was stopped");
			return NO;
		}
		if(intensity == 0.0f) {
			if(self.player && self.active) {
				[self.player stopAtTime:0 error:&error];
			}
			self.active = NO;
			return YES;
		}
		if(self.player == nil) {
			NSDictionary *hapticDict = @{
				CHHapticPatternKeyPattern: @[
					@{ CHHapticPatternKeyEvent: @{
						CHHapticPatternKeyTime: @(CHHapticTimeImmediate),
						CHHapticPatternKeyEventType: CHHapticEventTypeHapticContinuous,
						CHHapticPatternKeyEventDuration: @(GCHapticDurationInfinite),
						CHHapticPatternKeyEventParameters: @[
							@{
								CHHapticPatternKeyParameterID: CHHapticEventParameterIDHapticIntensity,
								CHHapticPatternKeyParameterValue: @(1)
							},
						],
					},
					},
				],
			};
			NSError *error;
			CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&error];
			if(error != nil) {
				LogError(@"Controller: could not create haptic pattern: %@", error.localizedDescription);
				return NO;
			}
			self.player = [self.engine createPlayerWithPattern:pattern error:&error];
			if(error != nil) {
				LogError(@"Controller: could not create haptic player: %@", error.localizedDescription);
				return NO;
			}
			self.active = NO;
		}
		CHHapticDynamicParameter *param = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl value:intensity relativeTime:0];
		[self.player sendParameters:@[param] atTime:0 error:&error];
		if(error != nil) {
			LogError(@"Controller: could not update haptic player: %@", error.localizedDescription);
			return NO;
		}
		if (!self.active) {
			[self.player startAtTime:0 error:&error];
			self.active = YES;
		}
	}
	return YES;
}

@end

#pragma mark -
@interface ControllerRumbleContext : NSObject {
	dispatch_block_t rumbleStop; // current stop block
}
@property(nonatomic, strong) ControllerRumbleMotor *lowFrequencyMotor;
@property(nonatomic, strong) ControllerRumbleMotor *highFrequencyMotor;
@end

@implementation ControllerRumbleContext

+ (instancetype)rumbleContextForController:(GCController *)controller {
	if (@available(iOS 14.0, *)) {
		ControllerRumbleMotor *low = [[ControllerRumbleMotor alloc] initWithController:controller locality:GCHapticsLocalityLeftHandle];
		ControllerRumbleMotor *high = [[ControllerRumbleMotor alloc] initWithController:controller locality:GCHapticsLocalityRightHandle];
		if(low && high) {
			return [[ControllerRumbleContext alloc] initWithLowFrequencyMotor:low andHighFrequencyMotor:high];
		}
	}
	return nil;
}

- (instancetype)initWithLowFrequencyMotor:(ControllerRumbleMotor *)lowfreq
                    andHighFrequencyMotor:(ControllerRumbleMotor *)highfreq {
	self = [super init];
	if(self) {
		self.lowFrequencyMotor = lowfreq;
		self.highFrequencyMotor = highfreq;
	}
	return self;
}

// high level rumble
- (void)rumbleAtStrength:(float)percent duration:(unsigned int)ms {
	if(@available(iOS 14.0, *)) {
		if(rumbleStop) {
			// ref: https://www.mattrajca.com/2016/04/23/canceling-blocks-in-gcd.html
			dispatch_block_cancel(rumbleStop);
			rumbleStop = nil;
		}
		percent = CLAMP(percent, 0, 1);
		[self rumbleWithLowFrequency:percent andHighFrequency:percent]; // on
		rumbleStop = dispatch_block_create(0, ^{
			[self rumbleWithLowFrequency:0 andHighFrequency:0]; // off
		});
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, CLAMP(ms / 1000.f, 0, 5000) * NSEC_PER_SEC), dispatch_get_main_queue(), rumbleStop);
	}
}

// low level rumble
- (BOOL)rumbleWithLowFrequency:(float)low andHighFrequency:(float)high {
	bool result = YES;
	result &= [self.lowFrequencyMotor setIntensity:low];
	result &= [self.highFrequencyMotor setIntensity:high];
	return result;
}

@end

#pragma mark -

@interface Controller () {
	NSMutableDictionary *buttonStates;
	NSMutableDictionary *axisStates;
	NSMutableArray *touchpadStates;
	NSObject *hapticEngine;
	id hapticPlayer;
}
@property(nonatomic, strong) ControllerRumbleContext *rumble API_AVAILABLE(ios(14.0));
@end

@implementation Controller

- (id)init {
	self = [super init];
	if(self) {
		buttonStates = [NSMutableDictionary dictionary];
		axisStates = [NSMutableDictionary dictionary];
		_index = -1; // GCControllerPlayerIndexUnset
	}
	return self;
}

- (void)dealloc {
	self.sensorsEnabled = NO;
}

- (void)setIndex:(int)index {
	_index = index;
	_name = [NSString stringWithFormat:@"gc%d", index+1];
	// set playerIndex after a short delay, this fixes the led blinking the correct index
	// then going dark for some reason
	NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(indexTimer:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)indexTimer:(NSTimer *)timer {
	switch(self.index) {
		case 0:
			self.controller.playerIndex = GCControllerPlayerIndex1;
			break;
		case 1:
			self.controller.playerIndex = GCControllerPlayerIndex2;
			break;
		case 2:
			self.controller.playerIndex = GCControllerPlayerIndex3;
			break;
		case 3:
			self.controller.playerIndex = GCControllerPlayerIndex4;
			break;
		default:
			self.controller.playerIndex = GCControllerPlayerIndexUnset;
			break;
	}
}

- (void)setController:(GCController *)controller {
	if(_controller == controller) {
		return;
	}
	_controller = controller;
	__weak Controller *weakSelf = self;

	// shared handlers
	GCControllerButtonValueChangedHandler buttonMenuHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		[weakSelf sendButton:@"back" state:pressed];
	};
	GCControllerButtonValueChangedHandler buttonAHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		[weakSelf sendButton:@"a" state:pressed];
	};
	GCControllerButtonValueChangedHandler buttonXHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		[weakSelf sendButton:@"x" state:pressed];
	};
	GCControllerAxisValueChangedHandler dpadAxisXHandler = ^(GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			[weakSelf sendButton:@"dpleft" state:YES];
		}
		else if(value > 0) {
			[weakSelf sendButton:@"dpright" state:YES];
		}
		else {
			[weakSelf sendButton:@"dpleft" state:NO];
			[weakSelf sendButton:@"dpright" state:NO];
		}
	};
	GCControllerAxisValueChangedHandler dpadAxisYHandler = ^(GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			[weakSelf sendButton:@"dpdown" state:YES];
		}
		else if(value > 0) {
			[weakSelf sendButton:@"dpup" state:YES];
		}
		else {
			[weakSelf sendButton:@"dpdown" state:NO];
			[weakSelf sendButton:@"dpup" state:NO];
		}
	};

	// menu buttons
	if(@available(iOS 13.0, *)) {
		// iOS:    back - [home] - [options] (options & home optional)
		// PS3:  select -  home  - start
		// SDL:    back -  guide - start (used here)
		if(self.controller.extendedGamepad) {
			self.controller.extendedGamepad.buttonMenu.valueChangedHandler = buttonMenuHandler;
			self.controller.extendedGamepad.buttonOptions.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
				[weakSelf sendButton:@"start" state:pressed];
			};
			if(@available(iOS 14.0, *)) {
				self.controller.extendedGamepad.buttonHome.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
					[weakSelf sendButton:@"guide" state:pressed];
				};
			}
		}
		else if(self.controller.microGamepad) {
			self.controller.microGamepad.buttonMenu.valueChangedHandler = buttonMenuHandler;
		}
	}
	else {
		// original pause button without state
		self.controller.controllerPausedHandler = ^(GCController *controller) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ pause", weakSelf.name);
			#endif
			[PureData sendControllerPause:weakSelf.name];
			[weakSelf.parent.osc sendControllerPause:weakSelf.name];

		};
	}

	// gamepad mappings
	// check extendedGamepad first as it will also appear as a (limited) microGamepad
	if(self.controller.extendedGamepad) {
		self.controller.extendedGamepad.buttonA.valueChangedHandler = buttonAHandler;
		self.controller.extendedGamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"b" state:pressed];
		};
		self.controller.extendedGamepad.buttonX.valueChangedHandler = buttonXHandler;
		self.controller.extendedGamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"y" state:pressed];
		};
		self.controller.extendedGamepad.dpad.xAxis.valueChangedHandler = dpadAxisXHandler;
		self.controller.extendedGamepad.dpad.yAxis.valueChangedHandler = dpadAxisYHandler;
		self.controller.extendedGamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"leftshoulder" state:pressed];
		};
		self.controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"lefttrigger" state:pressed];
		};
		self.controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"rightshoulder" state:pressed];
		};
		self.controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			[weakSelf sendButton:@"righttrigger" state:pressed];
		};
		self.controller.extendedGamepad.leftThumbstick.xAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
			[weakSelf sendAxis:@"leftx" value:value];
		};
		self.controller.extendedGamepad.leftThumbstick.yAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
			[weakSelf sendAxis:@"lefty" value:value];
		};
		self.controller.extendedGamepad.rightThumbstick.xAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
			[weakSelf sendAxis:@"rightx" value:value];
		};
		self.controller.extendedGamepad.rightThumbstick.yAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
			[weakSelf sendAxis:@"righty" value:value];
		};
		if(@available(iOS 12.1, *)) {
			self.controller.extendedGamepad.leftThumbstickButton.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
				[weakSelf sendButton:@"leftstick" state:pressed];
			};
			self.controller.extendedGamepad.rightThumbstickButton.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
				[weakSelf sendButton:@"rightstick" state:pressed];
			};
		}
		if(@available(iOS 14.5, *)) {
			if([self.controller.extendedGamepad isKindOfClass:GCDualSenseGamepad.class]) { // PS5 controller
				if(!self->touchpadStates) {self->touchpadStates = [NSMutableArray arrayWithArray:@[[ControllerTouchpadState new], [ControllerTouchpadState new]]];}
				GCDualSenseGamepad *dualsense = (GCDualSenseGamepad *)self.controller.extendedGamepad;
				dualsense.touchpadButton.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
					[weakSelf sendButton:@"touchpad" state:pressed];
				};
				dualsense.touchpadPrimary.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
					if(dpad.xAxis.value != 0.f || dpad.yAxis.value != 0.f) {
						[weakSelf sendTouchpad:0 finger:0
						                     x:((1.0f + dpad.xAxis.value) * 0.5f)
						                     y:(1.0f - (1.0f + dpad.yAxis.value) * 0.5f)
						                     pressure:1];
					}
					else {
						[weakSelf sendTouchpad:0 finger:0 x:0 y:0 pressure:0];
					}
				};
				dualsense.touchpadSecondary.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
					if(dpad.xAxis.value != 0.f || dpad.yAxis.value != 0.f) {
						[weakSelf sendTouchpad:0 finger:1
						                     x:((1.0f + dpad.xAxis.value) * 0.5f)
						                     y:(1.0f - (1.0f + dpad.yAxis.value) * 0.5f)
						                     pressure:1];
					}
					else {
						[weakSelf sendTouchpad:0 finger:1 x:0 y:0 pressure:0];
					}
				};
			}
			else if([self.controller.extendedGamepad isKindOfClass:GCDualShockGamepad.class]) { // PS4 controller
				if(!self->touchpadStates) {self->touchpadStates = [NSMutableArray arrayWithArray:@[[ControllerTouchpadState new], [ControllerTouchpadState new]]];}
				GCDualShockGamepad *dualshock = (GCDualShockGamepad *)self.controller.extendedGamepad;
				dualshock.touchpadButton.valueChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
					[weakSelf sendButton:@"touchpad" state:pressed];
				};
				dualshock.touchpadPrimary.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
					if(dpad.xAxis.value != 0.f || dpad.yAxis.value != 0.f) {
						[weakSelf sendTouchpad:0 finger:0
						                     x:((1.0f + dpad.xAxis.value) * 0.5f)
						                     y:(1.0f - (1.0f + dpad.yAxis.value) * 0.5f)
						                     pressure:1];
					}
					else {
						[weakSelf sendTouchpad:0 finger:0 x:0 y:0 pressure:0];
					}
				};
				dualshock.touchpadSecondary.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
					if(dpad.xAxis.value != 0.f || dpad.yAxis.value != 0.f) {
						[weakSelf sendTouchpad:0 finger:1
						                     x:((1.0f + dpad.xAxis.value) * 0.5f)
						                     y:(1.0f - (1.0f + dpad.yAxis.value) * 0.5f)
						                     pressure:1];
					}
					else {
						[weakSelf sendTouchpad:0 finger:1 x:0 y:0 pressure:0];
					}
				};
			}
		}
		LogVerbose(@"Controllers: extended gamepad");
	}
	else if(self.controller.microGamepad) {
		self.controller.microGamepad.buttonA.valueChangedHandler = buttonAHandler;
		self.controller.microGamepad.buttonX.valueChangedHandler = buttonXHandler;
		self.controller.microGamepad.dpad.xAxis.valueChangedHandler = dpadAxisXHandler;
		self.controller.microGamepad.dpad.yAxis.valueChangedHandler = dpadAxisYHandler;
		self.controller.microGamepad.allowsRotation = YES; // match dpad orientation to device rotation
		LogVerbose(@"Controllers: micro gamepad");
	}

	if(@available(iOS 14.0, *)) {
		if(self.controller.motion) {
			LogVerbose(@"Controllers: gamepad has sensors");
			self.controller.motion.valueChangedHandler = ^(GCMotion * _Nonnull motion) {
				if(weakSelf.nativeSensors) {
					[weakSelf sendAccel:motion.acceleration.x
					                  y:motion.acceleration.y
					                  z:motion.acceleration.z];
					if(motion.hasRotationRate) {
						[weakSelf sendGyro:motion.rotationRate.x
						                 y:motion.rotationRate.y
						                 z:motion.rotationRate.z];
					}
				}
				else { // match SDL values and orientation
					[weakSelf sendAccel:-motion.acceleration.x * SDL_STANDARD_GRAVITY
					                  y:-motion.acceleration.z * SDL_STANDARD_GRAVITY
					                  z:motion.acceleration.y * SDL_STANDARD_GRAVITY];
					if(motion.hasRotationRate) {
						[weakSelf sendGyro:motion.rotationRate.x
						                 y:motion.rotationRate.z
						                 z:-motion.rotationRate.y];
					}

				}
			};
		}
		if(self.controller.light) {
			LogVerbose(@"Controllers: gamepad has led");
		}
		if(self.controller.haptics) {
			LogVerbose(@"Controllers: gamepad has rumble");
			self.rumble = [ControllerRumbleContext rumbleContextForController:self.controller];
		}
	}
}

- (void)sendButton:(NSString *)button state:(BOOL)pressed {
	if([self->buttonStates[button] boolValue] != pressed) {
		#ifdef DEBUG_CONTROLLERS
			LogVerbose(@"%@ button: %@ %d", self.name, button, (int)pressed);
		#endif
		[PureData sendController:self.name button:button state:pressed];
		[self.parent.osc sendController:self.name button:button state:pressed];
		self->buttonStates[button] = [NSNumber numberWithBool:pressed];
	}
}

- (void)sendAxis:(NSString *)axis value:(double)value {
	if([self->axisStates[axis] floatValue] != value) {
		#ifdef DEBUG_CONTROLLERS
			LogVerbose(@"%@ axis: %@ %g", self.name, axis, value);
		#endif
		[PureData sendController:self.name axis:axis value:value];
		[self.parent.osc sendController:self.name axis:axis value:value];
		self->axisStates[axis] = [NSNumber numberWithFloat:value];
	}
}

// simple dpad event -> SDL-style touchpad event, assume input 0,0 to be touch release
// from SDL3 src/joystick/apple/SDL_mfijoystick.m
- (void)sendTouchpad:(int)touchpad finger:(int)finger x:(float)x y:(float)y pressure:(float)pressure {
	ControllerTouchpadState *state = self->touchpadStates[touchpad];
	NSString *eventType;
	if(x != 0.f && y != 0.f) { // press
		eventType = (state->pressed ? @"xy" : @"down");
		state->pressed = YES;
		state->x = x;
		state->y = y;
	}
	else { // release, reuse last position
		if(state->x == 0.f && state->y == 0.f) {return;} // swallow double-releases
		eventType = @"up";
		state->pressed = NO;
		x = state->x;
		y = state->y;
	}
	#ifdef DEBUG_CONTROLLERS
		LogVerbose(@"%@ touchpad: %@ %d %d %g %g %g", self.name, eventType, touchpad, finger, x, y, pressure);
	#endif
	[PureData sendController:self.name touchpadEvent:eventType forIndex:touchpad finger:finger x:x y:y pressure:pressure];
	[self.parent.osc sendController:self.name touchpadEvent:eventType forIndex:touchpad finger:finger x:x y:y pressure:pressure];
}

- (void)setColorRed:(float)red green:(float)green blue:(float)blue {
	if(@available(iOS 14.0, *)) {
		if(self.controller.light) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ color: %g %g %g", self.name, red, green, blue);
			#endif
			self.controller.light.color =
				[[GCColor alloc] initWithRed:red/255.f green:green/255.f blue:blue/255.f];
		}
	}
}

- (void)rumbleAtStrength:(float)percent duration:(unsigned int)ms {
	if(@available(iOS 14.0, *)) {
		#ifdef DEBUG_CONTROLLERS
			LogDebug(@"%@ rumble: %g %d", self.name, percent, ms);
		#endif
		[self.rumble rumbleAtStrength:percent duration:ms];
	}
}

- (void)sendAccel:(float)x y:(float)y z:(float)z {
	#ifdef DEBUG_CONTROLLERS
		LogDebug(@"%@ accel: %g %g %g", self.name, x, y, z);
	#endif
	[self.parent.osc sendController:self.name accel:x y:y z:z];
	[PureData sendController:self.name accel:x y:y z:z];
}

- (void)sendGyro:(float)x y:(float)y z:(float)z {
	#ifdef DEBUG_CONTROLLERS
		LogDebug(@"%@ gyro: %g %g %g", self.name, x, y, z);
	#endif
	[self.parent.osc sendController:self.name gyro:x y:y z:z];
	[PureData sendController:self.name gyro:x y:y z:z];
}

- (NSArray *)query {
	int buttons = 0;
	int axes = 0;
	int touchpads = 0;
	int sensors = 0;
	BOOL rumble = NO;
	BOOL led = NO;
	if(self.controller.extendedGamepad) {
		buttons = 13; // 4 buttons, 4 dpad, 2 shoulders, 2 triggers, 1 menu
		axes = 4; // 2 thumbsticks
		if(@available(iOS 12.1, *)) { // optional thumbstick buttons
			if(self.controller.extendedGamepad.leftThumbstickButton) {buttons++;}
			if(self.controller.extendedGamepad.rightThumbstickButton) {buttons++;}
		}
		if(@available(iOS 14.0, *)) { // optional home and options
			if(self.controller.extendedGamepad.buttonHome) {buttons++;}
			if(self.controller.extendedGamepad.buttonOptions) {buttons++;}
		}
		if(@available(iOS 14.5, *)) { // optional touchpads
			if([self.controller.extendedGamepad isKindOfClass:GCDualSenseGamepad.class] || // PS5 controller
			   [self.controller.extendedGamepad isKindOfClass:GCDualSenseGamepad.class]) { // PS4 controller
				touchpads = 1;
			}
		}
	}
	else if(self.controller.microGamepad) {
		buttons = 3; // 2 buttons, 1 menu
		axes = 2; // analog dpad
	}
	if(@available(iOS 14.0, *)) {
		if(self.controller.motion) {
			if(self.controller.motion.hasRotationRate) {sensors++;} // gyro
			if(self.controller.motion.hasGravityAndUserAcceleration) {sensors++;} // accel
		}
		if(self.rumble) {
			rumble = YES;
		}
		if(self.controller.light) {
			led = YES;
		}
	}
	return @[@(self.index), self.name, @(buttons), @(axes), @(touchpads), @(sensors), @(rumble), @(led)];
}

#pragma mark Overridden Getters/Setters

- (BOOL)sensorsEnabled {
	if(@available(iOS 14.0, *)) {
		if(self.controller.motion) {
			return self.controller.motion.sensorsActive;
		}
	}
	return NO;
}

- (void)setSensorsEnabled:(BOOL)sensorsEnabled {
	if(@available(iOS 14.0, *)) {
		if(self.controller.motion) {
			self.controller.motion.sensorsActive = sensorsEnabled;
		}
	}
}

@end
