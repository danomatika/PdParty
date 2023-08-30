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

@interface Controller () {
	NSMutableDictionary *buttonStates;
	NSMutableDictionary *axisStates;
}
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
		if(self.controller.microGamepad) {
			self.controller.microGamepad.buttonMenu.valueChangedHandler = buttonMenuHandler;
		}
		else if(self.controller.extendedGamepad) {
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
	if(self.controller.microGamepad) {
		self.controller.microGamepad.buttonA.valueChangedHandler = buttonAHandler;
		self.controller.microGamepad.buttonX.valueChangedHandler = buttonXHandler;
		self.controller.microGamepad.dpad.xAxis.valueChangedHandler = dpadAxisXHandler;
		self.controller.microGamepad.dpad.yAxis.valueChangedHandler = dpadAxisYHandler;
		self.controller.microGamepad.allowsRotation = YES; // match dpad orientation to device rotation
		LogVerbose(@"Controllers: micro gamepad");
	}
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
		LogVerbose(@"Controllers: extended gamepad");
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
			LogVerbose(@"%@ axis: %@ %f", self.name, axis, value);
		#endif
		[PureData sendController:self.name axis:axis value:value];
		[self.parent.osc sendController:self.name axis:axis value:value];
		self->axisStates[axis] = [NSNumber numberWithFloat:value];
	}
}

@end
