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
}

- (void)startDiscovery {
	_discovering = YES;
	[GCController startWirelessControllerDiscoveryWithCompletionHandler: ^(void) {
		_discovering = NO;
		DDLogVerbose(@"Controllers: game controller discovery timed out");
	}];
	DDLogVerbose(@"Controllers: game controller discovery enabled");
}

- (void)stopDiscovery {
	if(self.discovering) {
		[GCController stopWirelessControllerDiscovery];
		DDLogVerbose(@"Controllers: game controller discovery disabled");
	}
}

+ (BOOL)controllersAvailable {
	return [Util deviceOSVersion] >= 7.0;
}

#pragma mark GC Notifications

- (void)controllerDidConnect:(NSNotification *)notification {
	Controller *controller = [[Controller alloc] init];
	controller.index = [self firstAvailableIndex];
	controller.parent = self;
	controller.controller = (GCController *)[notification object];
	[self.controllers addObject:controller];
	[self sortControllers];
	[PureData sendEvent:@"connect" forController:controller.name];
	[self.osc sendEvent:@"connect" forController:controller.name];
	DDLogVerbose(@"Controllers: controller connected: %@", controller.name);
}

- (void)controllerDidDisconnect:(NSNotification *)notification {
	GCController *controller = (GCController *)[notification object];
	NSString *name;
	for(Controller *c in self.controllers) {
		if(c.controller == controller) {
			name = c.name;
			[self.controllers removeObject:c];
			break;
		}
	}
	if(name) {
		[PureData sendEvent:@"disconnect" forController:name];
		[self.osc sendEvent:@"disconnect" forController:name];
		DDLogVerbose(@"Controllers: controller disconnected: %@", name);
	}
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
		DDLogVerbose(@"Controllers: game controllers enabled");
	}
	else {
		[self.controllers removeAllObjects];
		[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                    name:GCControllerDidConnectNotification
                                                      object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:GCControllerDidDisconnectNotification
												      object:nil];
		DDLogVerbose(@"Controllers: game controllers disabled");
	}
}

#pragma mark Private

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
		self.index = GCControllerPlayerIndexUnset;
	}
	return self;
}

- (void)setIndex:(int)index {
	_index = index;
	_name = [NSString stringWithFormat:@"gc%d", index+1];
	if([Util deviceOSVersion] >= 8.0) {
		switch(index) {
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
	else {
		self.controller.playerIndex = index;
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
//		DDLogVerbose(@"%@ pause", weakSelf.name);
		[PureData sendControllerPause:weakSelf.name];
		[weakSelf.parent.osc sendControllerPause:weakSelf.name];
		
	};
	self.controller.gamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"a"] boolValue] != pressed) {
//			DDLogVerbose(@"%@ button: a %d", weakSelf.name, (int)pressed);
			[PureData sendController:weakSelf.name button:@"a" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"a" state:pressed];
			buttonStates[@"a"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"b"] boolValue] != pressed) {
//			DDLogVerbose(@"%@ button: b %d", weakSelf.name, (int)pressed);
			[PureData sendController:weakSelf.name button:@"b" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"b" state:pressed];
			buttonStates[@"b"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"x"] boolValue] != pressed) {
//			DDLogVerbose(@"%@ button: x %d", weakSelf.name, (int)pressed);
			[PureData sendController:weakSelf.name button:@"x" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"x" state:pressed];
			buttonStates[@"x"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"y"] boolValue] != pressed) {
//			DDLogVerbose(@"%@ button: y %d", weakSelf.name, (int)pressed);
			[PureData sendController:weakSelf.name button:@"y" state:pressed];
			[weakSelf.parent.osc sendController:weakSelf.name button:@"y" state:pressed];
			buttonStates[@"y"] = [NSNumber numberWithBool:pressed];
		}
	};
	self.controller.gamepad.dpad.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpleft"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpleft 1", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpleft" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:YES];
				buttonStates[@"dpleft"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpright"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpright 1", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpright" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:YES];
				buttonStates[@"dpright"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpleft"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpleft 0", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpleft" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpleft" state:NO];
				buttonStates[@"dpleft"] = @NO;
			}
			if([buttonStates[@"dpright"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpright 0", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpright" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpright" state:NO];
				buttonStates[@"dpright"] = @NO;
			}
		}
	};
	self.controller.gamepad.dpad.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpdown"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpdown 1", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpdown" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:YES];
				buttonStates[@"dpdown"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpup"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpup 1", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpup" state:YES];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpup" state:YES];
				buttonStates[@"dpup"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpdown"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpdown 0", weakSelf.name);
				[PureData sendController:weakSelf.name button:@"dpdown" state:NO];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"dpdown" state:NO];
				buttonStates[@"dpdown"] = @NO;
			}
			if([buttonStates[@"dpup"] boolValue]) {
//				DDLogVerbose(@"%@ button: dpup 0", weakSelf.name);
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
//				DDLogVerbose(@"%@ button: leftshoulder %d", weakSelf.name, (int)pressed);
				[PureData sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"leftshoulder" state:pressed];
				buttonStates[@"leftshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"lefttrigger"] boolValue] != pressed) {
//				DDLogVerbose(@"%@ button: lefttrigger %d", weakSelf.name, (int)pressed);
				[PureData sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"lefttrigger" state:pressed];
				buttonStates[@"lefttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"rightshoulder"] boolValue] != pressed) {
//				DDLogVerbose(@"%@ button: rightshoulder %d", weakSelf.name, (int)pressed);
				[PureData sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"rightshoulder" state:pressed];
				buttonStates[@"rightshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"righttrigger"] boolValue] != pressed) {
//				DDLogVerbose(@"%@ button: righttrigger %d", weakSelf.name, (int)pressed);
				[PureData sendController:weakSelf.name button:@"righttrigger" state:pressed];
				[weakSelf.parent.osc sendController:weakSelf.name button:@"righttrigger" state:pressed];
				buttonStates[@"righttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"leftx"] floatValue] != value) {
//				DDLogVerbose(@"%@ axis: leftx %f", weakSelf.name, value);
				[PureData sendController:weakSelf.name axis:@"leftx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"leftx" value:value];
				axisStates[@"leftx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.leftThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"lefty"] floatValue] != value) {
//				DDLogVerbose(@"%@ axis: lefty %f", weakSelf.name, value);
				[PureData sendController:weakSelf.name axis:@"lefty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"lefty" value:value];
				axisStates[@"lefty"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"rightx"] floatValue] != value) {
//				DDLogVerbose(@"%@ axis: rightx %f", weakSelf.name, value);
				[PureData sendController:weakSelf.name axis:@"rightx" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"rightx" value:value];
				axisStates[@"rightx"] = [NSNumber numberWithFloat:value];
			}
		};
		self.controller.extendedGamepad.rightThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"righty"] floatValue] != value) {
//				DDLogVerbose(@"%@ axis: righty %f", weakSelf.name, value);
				[PureData sendController:weakSelf.name axis:@"righty" value:value];
				[weakSelf.parent.osc sendController:weakSelf.name axis:@"righty" value:value];
				axisStates[@"righty"] = [NSNumber numberWithFloat:value];
			}
		};
		DDLogVerbose(@"Controller: extended gamepad");
	}
	else {
		DDLogVerbose(@"Controller: gamepad");
	}
}

@end
