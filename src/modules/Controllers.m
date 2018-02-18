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
		self.controllers = [NSMutableArray new];
		
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                    name:GCControllerDidConnectNotification
                                                      object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:GCControllerDidDisconnectNotification
												  object:nil];
	[self disconnectAll:YES];
}

- (void)startDiscovery {
	_discovering = YES;
	[GCController startWirelessControllerDiscoveryWithCompletionHandler: ^(void) {
		_discovering = NO;
		DDLogVerbose(@"Controllers: discovery timed out");
	}];
	DDLogVerbose(@"Controllers: discovery enabled");
}

- (void)stopDiscovery {
	if(self.discovering) {
		[GCController stopWirelessControllerDiscovery];
		DDLogVerbose(@"Controllers: discovery disabled");
	}
}

- (void)updateConnectedControllers {
	DDLogVerbose(@"Controllers: updating");
	
	// build array of currently known controllers
	NSMutableArray *known = [NSMutableArray new];
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
			DDLogVerbose(@"Controllers: found new controller");
			[self connect:c];
		}
	}
	
	// anything left over can be removed
	for(GCController *c in known) {
		DDLogVerbose(@"Controllers: disconnecting stale controller");
		[self disconnect:c unset:NO];
	}
}

+ (BOOL)controllersAvailable {
	return [Util deviceOSVersion] >= 7.0;
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
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(controllerDidConnect:)
		                                             name:GCControllerDidConnectNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(controllerDidDisconnect:)
		                                             name:GCControllerDidDisconnectNotification
		                                           object:nil];
		DDLogVerbose(@"Controllers: enabled");
		[self updateConnectedControllers];
	}
	else {
		[self disconnectAll:YES];
		[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                    name:GCControllerDidConnectNotification
                                                      object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:GCControllerDidDisconnectNotification
												      object:nil];
		DDLogVerbose(@"Controllers: disabled");
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
		DDLogVerbose(@"Controllers: connected %@ (%@)", c.name, controller.vendorName);
	}
	else {
		DDLogVerbose(@"Controllers: connected %@", c.name);
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
	if(remove) {
		[PureData sendEvent:@"disconnect" forController:name];
		[self.osc sendEvent:@"disconnect" forController:name];
		if(controller.vendorName) {
			DDLogVerbose(@"Controllers: disconnected %@ (%@)", name, controller.vendorName);
		}
		else {
			DDLogVerbose(@"Controllers: disconnected %@", name);
		}
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
		buttonStates = [NSMutableDictionary new];
		axisStates = [NSMutableDictionary new];
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
			DDLogVerbose(@"%@ pause", weakSelf.name);
		#endif
		[PureData sendControllerPause:weakSelf.name];
		[weakSelf.parent.osc sendControllerPause:weakSelf.name];
		
	};
	self.controller.gamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"a"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				DDLogVerbose(@"%@ button: a %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"a" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"a" state:pressed];
			buttonStates[@"a"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"b"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				DDLogVerbose(@"%@ button: b %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"b" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"b" state:pressed];
			buttonStates[@"b"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"x"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				DDLogVerbose(@"%@ button: x %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"x" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"x" state:pressed];
			buttonStates[@"x"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"y"] boolValue] != pressed) {
			#ifdef DEBUG_CONTROLLERS
				DDLogVerbose(@"%@ button: y %d", weakSelf.name, (int)pressed);
			#endif
			[PureData sendController:weakSelf.name button:@"y" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"y" state:pressed];
			buttonStates[@"y"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.dpad.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpleft"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpleft 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpleft" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:YES];
				buttonStates[@"dpleft"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpright"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpright 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpright" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:YES];
				buttonStates[@"dpright"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpleft"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpleft 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpleft" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:NO];
				buttonStates[@"dpleft"] = @NO;
			}
			if([buttonStates[@"dpright"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpright 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpright" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:NO];
				buttonStates[@"dpright"] = @NO;
			}
		}
	};
	self.controller.gamepad.dpad.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpdown"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpdown 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpdown" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:YES];
				buttonStates[@"dpdown"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpup"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpup 1", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpup" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpup" state:YES];
				buttonStates[@"dpup"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpdown"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpdown 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpdown" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:NO];
				buttonStates[@"dpdown"] = @NO;
			}
			if([buttonStates[@"dpup"] boolValue]) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: dpup 0", weakSelf.name);
				#endif
				[PureData sendController:weakSelf.name button:@"dpup" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpup" state:NO];
				buttonStates[@"dpup"] = @NO;
			}
		}
	};
	
	// extended gamepad mappings
	if(self.controller.extendedGamepad) {
		self.controller.extendedGamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"leftshoulder"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: leftshoulder %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				buttonStates[@"leftshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"lefttrigger"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: lefttrigger %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				buttonStates[@"lefttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"rightshoulder"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: rightshoulder %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				buttonStates[@"rightshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"righttrigger"] boolValue] != pressed) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ button: righttrigger %d", weakSelf.name, (int)pressed);
				#endif
				[PureData sendController:weakSelf.name button:@"righttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"righttrigger" state:pressed];
				buttonStates[@"righttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"leftx"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ axis: leftx %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"leftx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"leftx" value:value];
				axisStates[@"leftx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"lefty"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ axis: lefty %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"lefty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"lefty" value:value];
				axisStates[@"lefty"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"rightx"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ axis: rightx %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"rightx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"rightx" value:value];
				axisStates[@"rightx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"righty"] floatValue] != value) {
				#ifdef DEBUG_CONTROLLERS
					DDLogVerbose(@"%@ axis: righty %f", weakSelf.name, value);
				#endif
				[PureData sendController:weakSelf.name axis:@"righty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"righty" value:value];
				axisStates[@"righty"] = [NSNumber numberWithFloat:value];
			}
		};
		DDLogVerbose(@"Controllers: extended gamepad");
	}
	else {
		DDLogVerbose(@"Controllers: gamepad");
	}
}

@end
