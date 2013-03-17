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
#import "Osc.h"

#import "Log.h"
#import "PureData.h"

@interface Osc () {
	OSCConnection *connection;
}
@end

@implementation Osc

- (id)init {
	self = [super init];
	if(self) {
		connection = [[OSCConnection alloc] init];
		connection.delegate = self;
		connection.continuouslyReceivePackets = YES;
		
		self.sendHost = @"127.0.0.1";
		self.sendPort = 8080;
		self.listenPort = 8088;
		
		// do a bind at the beginning so sending works
		NSError *error;
		if(![connection bindToAddress:nil port:self.listenPort error:&error]) {
			DDLogError(@"OSC: Could not bind UDP connection: %@", error);
		}
	}
	return self;
}

#pragma OSCConnectionDelegate

- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet {
	 NSLog(@"OSC message to port %@: %@", packet.address, [packet.arguments description]);
}

#pragma mark Send Events

- (void)sendBang {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_OSC_ADDR;
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendFloat:(float)f {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_OSC_ADDR;
	[message addFloat:f];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendSymbol:(NSString *)symbol {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_OSC_ADDR;
	[message addString:symbol];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendList:(NSArray *)list {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_OSC_ADDR;
	for(NSObject *object in list) {
		[message addArgument:object];
	}
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_TOUCH_ADDR;
	[message addString:eventType];
	[message addFloat:id+1];
	[message addFloat:x];
	[message addFloat:y];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendAccel:(float)x y:(float)y z:(float)z {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address =OSC_ACCEL_ADDR;
	[message addFloat:x];
	[message addFloat:y];
	[message addFloat:z];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendRotate:(float)degrees newOrientation:(NSString*)orientation {
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_ROTATE_ADDR;
	[message addFloat:degrees];
	[message addString:orientation];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

#pragma mark Overridden Getters / Setters

- (void)setListening:(BOOL)listening {
	if(listening == connection.isConnected) {
		return;
	}
	
	if(listening) {
		NSError *error;
		if(![connection bindToAddress:nil port:self.listenPort error:&error]) {
			DDLogError(@"OSC: Could not bind UDP connection: %@", error);
			return;
		}
		DDLogVerbose(@"OSC: started listening on port %d", connection.localPort);
		[connection receivePacket];
	}
	else {
		[connection disconnect];
		DDLogVerbose(@"OSC: stopped listening on port %d", connection.localPort);
	}
}

- (BOOL)isListening {
	return connection.isConnected;
}

@end
