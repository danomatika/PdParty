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

	// gamepad mappings
	self.controller.controllerPausedHandler = ^(GCController *controller) {
		#ifdef DEBUG_CONTROLLERS
			LogVerbose(@"%@ pause", weakSelf.name);
		#endif
		[PureData sendControllerPause:weakSelf.name];
		[weakSelf.parent.osc sendControllerPause:weakSelf.name];
		
	};
	self.controller.extendedGamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([self->buttonStates[@"a"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ button: a %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"a" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"a" state:pressed];
			self->buttonStates[@"a"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.extendedGamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([self->buttonStates[@"b"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ button: b %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"b" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"b" state:pressed];
			self->buttonStates[@"b"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.extendedGamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([self->buttonStates[@"x"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ button: x %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"x" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"x" state:pressed];
			self->buttonStates[@"x"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.extendedGamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([self->buttonStates[@"y"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				LogVerbose(@"%@ button: y %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"y" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"y" state:pressed];
			self->buttonStates[@"y"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.extendedGamepad.dpad.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![self->buttonStates[@"dpleft"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpleft 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpleft" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:YES];
				self->buttonStates[@"dpleft"] = @YES;
			}
		}
		else if(value > 0) {
			if(![self->buttonStates[@"dpright"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpright 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpright" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:YES];
				self->buttonStates[@"dpright"] = @YES;
			}
		}
		else {
			if([self->buttonStates[@"dpleft"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpleft 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpleft" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:NO];
				self->buttonStates[@"dpleft"] = @NO;
			}
			if([self->buttonStates[@"dpright"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpright 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpright" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:NO];
				self->buttonStates[@"dpright"] = @NO;
			}
		}
	};
	self.controller.extendedGamepad.dpad.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![self->buttonStates[@"dpdown"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpdown 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpdown" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:YES];
				self->buttonStates[@"dpdown"] = @YES;
			}
		}
		else if(value > 0) {
			if(![self->buttonStates[@"dpup"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpup 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpup" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpup" state:YES];
				self->buttonStates[@"dpup"] = @YES;
			}
		}
		else {
			if([self->buttonStates[@"dpdown"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpdown 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpdown" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:NO];
				self->buttonStates[@"dpdown"] = @NO;
			}
			if([self->buttonStates[@"dpup"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: dpup 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpup" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpup" state:NO];
				self->buttonStates[@"dpup"] = @NO;
			}
		}
	};
	
	// extended gamepad mappings
	if(self.controller.extendedGamepad) {
		self.controller.extendedGamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([self->buttonStates[@"leftshoulder"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: leftshoulder %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				self->buttonStates[@"leftshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([self->buttonStates[@"lefttrigger"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: lefttrigger %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				self->buttonStates[@"lefttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([self->buttonStates[@"rightshoulder"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: rightshoulder %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				self->buttonStates[@"rightshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([self->buttonStates[@"righttrigger"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ button: righttrigger %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"righttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"righttrigger" state:pressed];
				self->buttonStates[@"righttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([self->axisStates[@"leftx"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ axis: leftx %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"leftx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"leftx" value:value];
				self->axisStates[@"leftx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([self->axisStates[@"lefty"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ axis: lefty %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"lefty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"lefty" value:value];
				self->axisStates[@"lefty"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([self->axisStates[@"rightx"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ axis: rightx %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"rightx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"rightx" value:value];
				self->axisStates[@"rightx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([self->axisStates[@"righty"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					LogVerbose(@"%@ axis: righty %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"righty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"righty" value:value];
				self->axisStates[@"righty"] = [NSNumber numberWithFloat:value];
			}
		};
		LogVerbose(@"Controllers: extended gamepad");
	}
	else {
		LogVerbose(@"Controllers: gamepad");
	}
}

@end
