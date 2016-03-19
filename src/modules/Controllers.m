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

#import "Log.h"

@interface Controllers () {
	NSMutableDictionary *buttonStates;
	NSMutableDictionary *axisStates;
}
@end

@implementation Controllers

- (id)init {
	self = [super init];
	if(self) {
		buttonStates = [NSMutableDictionary new];
		axisStates = [NSMutableDictionary new];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(controllerDidConnect:)
		                                             name:GCControllerDidConnectNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(controllerDidDisconnect:)
		                                             name:GCControllerDidDisconnectNotification
		                                           object:nil];
		
		[GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
	
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

- (void)controllerDidConnect:(NSNotification *)notification {
	GCController *controller =(GCController *)[notification object];
	DDLogVerbose(@"Controllers: controller connected: %@", [controller vendorName]);
	
	// gamepad mappings
	controller.controllerPausedHandler = ^(GCController *controller) {
		DDLogVerbose(@"pause: 1");
	};
	controller.gamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"a"] boolValue] != pressed) {
			DDLogVerbose(@"a: %d", (int)pressed);
			buttonStates[@"a"] = [NSNumber numberWithBool:pressed];
		}
	};
	controller.gamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"b"] boolValue] != pressed) {
			DDLogVerbose(@"b: %d", (int)pressed);
			buttonStates[@"b"] = [NSNumber numberWithBool:pressed];
		}
	};
	controller.gamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"x"] boolValue] != pressed) {
			DDLogVerbose(@"x: %d", (int)pressed);
			buttonStates[@"x"] = [NSNumber numberWithBool:pressed];
		}
	};
	controller.gamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		if([buttonStates[@"y"] boolValue] != pressed) {
			DDLogVerbose(@"y: %d", (int)pressed);
			buttonStates[@"y"] = [NSNumber numberWithBool:pressed];
		}
	};
	controller.gamepad.dpad.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpleft"] boolValue]) {
				DDLogVerbose(@"dpleft: 1");
				buttonStates[@"dpleft"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpright"] boolValue]) {
				DDLogVerbose(@"dpright: 1");
				buttonStates[@"dpright"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpleft"] boolValue]) {
				DDLogVerbose(@"dpleft: 0");
				buttonStates[@"dpleft"] = @NO;
			}
			if([buttonStates[@"dpright"] boolValue]) {
				DDLogVerbose(@"dpright: 0");
				buttonStates[@"dpright"] = @NO;
			}
		}
	};
	controller.gamepad.dpad.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
		if(value < 0) {
			if(![buttonStates[@"dpdown"] boolValue]) {
				DDLogVerbose(@"dpdown: 1");
				buttonStates[@"dpdown"] = @YES;
			}
		}
		else if(value > 0) {
			if(![buttonStates[@"dpup"] boolValue]) {
				DDLogVerbose(@"dpup: 1");
				buttonStates[@"dpup"] = @YES;
			}
		}
		else {
			if([buttonStates[@"dpdown"] boolValue]) {
				DDLogVerbose(@"dpdown: 0");
				buttonStates[@"dpdown"] = @NO;
			}
			if([buttonStates[@"dpup"] boolValue]) {
				DDLogVerbose(@"dpup: 0");
				buttonStates[@"dpup"] = @NO;
			}
		}
	};
	
	// extended gamepad mappings
	if(controller.extendedGamepad) {
		controller.extendedGamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"leftshoulder"] boolValue] != pressed) {
				DDLogVerbose(@"leftshoulder: %d", (int)pressed);
				buttonStates[@"leftshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"lefttrigger"] boolValue] != pressed) {
				DDLogVerbose(@"lefttrigger: %d", (int)pressed);
				buttonStates[@"lefttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"rightshoulder"] boolValue] != pressed) {
				DDLogVerbose(@"rightshoulder: %d", (int)pressed);
				buttonStates[@"rightshoulder"] = [NSNumber numberWithBool:pressed];
			}
		};
		controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
			if([buttonStates[@"righttrigger"] boolValue] != pressed) {
				DDLogVerbose(@"righttrigger: %d", (int)pressed);
				buttonStates[@"righttrigger"] = [NSNumber numberWithBool:pressed];
			}
		};
		controller.extendedGamepad.leftThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"leftx"] floatValue] != value) {
				DDLogVerbose(@"leftx: %f", value);
				axisStates[@"leftx"] = [NSNumber numberWithFloat:value];
			}
		};
		controller.extendedGamepad.leftThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"lefty"] floatValue] != value) {
				DDLogVerbose(@"lefty: %f", value);
				axisStates[@"lefty"] = [NSNumber numberWithFloat:value];
			}
		};
		controller.extendedGamepad.rightThumbstick.xAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"rightx"] floatValue] != value) {
				DDLogVerbose(@"rightx: %f", value);
				axisStates[@"rightx"] = [NSNumber numberWithFloat:value];
			}
		};
		controller.extendedGamepad.rightThumbstick.yAxis.valueChangedHandler = ^ (GCControllerAxisInput *axis, float value) {
			if([axisStates[@"righty"] floatValue] != value) {
				DDLogVerbose(@"righty: %f", value);
				axisStates[@"righty"] = [NSNumber numberWithFloat:value];
			}
		};
	}
}

- (void)controllerDidDisconnect:(NSNotification *)notification {
	GCController *controller = (GCController *)[notification object];
	DDLogVerbose(@"Controllers: controller disconnected: %@", [controller vendorName]);
}

@end
