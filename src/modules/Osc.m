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
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		self.sendHost = [defaults objectForKey:@"oscSendHost"];
		self.sendPort = [defaults integerForKey:@"oscSendPort"];
		self.listenPort = [defaults integerForKey:@"oscListenPort"];
		
		// do a bind at the beginning so sending works
		NSError *error;
		if(![connection bindToAddress:nil port:self.listenPort error:&error]) {
			DDLogError(@"OSC: could not bind UDP connection: %@", error);
		}
		[connection disconnect];
		
		self.accelSendingEnabled = [defaults boolForKey:@"accelSendingEnabled"];
		self.touchSendingEnabled = [defaults boolForKey:@"touchSendingEnabled"];
		self.locateSendingEnabled = [defaults boolForKey:@"locateSendingEnabled"];
		self.keySendingEnabled = [defaults boolForKey:@"keySendingEnabled"];
		self.printSendingEnabled = [defaults boolForKey:@"printSendingEnabled"];
		
		// should start listening if saved
		self.listening = [defaults boolForKey:@"oscServerEnabled"];
	}
	return self;
}

#pragma OSCConnectionDelegate

- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet {
//	#ifdef DEBUG
//		DDLogVerbose(@"OSC message to %@: %@", packet.address, [packet.arguments description]);
//	#endif
	[PureData sendOscMessage:packet.address withArguments:packet.arguments];
}

#pragma mark Send Events

- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments {
	if(!self.listening) return;
	OSCMutableMessage *m = [[OSCMutableMessage alloc] init];
    m.address = address;
	for(NSObject *object in arguments) {
		[m addArgument:object];
	}
	[connection sendPacket:m toHost:self.sendHost port:self.sendPort];
}

- (void)sendAccel:(float)x y:(float)y z:(float)z {
	if(!self.listening || !self.accelSendingEnabled) return;
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_ACCEL_ADDR;
	[message addFloat:x];
	[message addFloat:y];
	[message addFloat:z];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y {
	if(!self.listening || !self.touchSendingEnabled) return;
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_TOUCH_ADDR;
	[message addString:eventType];
	[message addFloat:id+1];
	[message addFloat:x];
	[message addFloat:y];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendLocate:(float)lat lon:(float)lon alt:(float)alt speed:(float)speed
	horzAccuracy:(float)horzAccuracy vertAccuracy:(float)vertAccuracy
	timestamp:(NSString *)timestamp {
	if(!self.listening || !self.locateSendingEnabled) return;
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_LOCATE_ADDR;
	[message addFloat:lat];
	[message addFloat:lon];
	[message addFloat:alt];
	[message addFloat:speed];
	[message addFloat:horzAccuracy];
	[message addFloat:vertAccuracy];
	[message addString:timestamp];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendKey:(int)key {
	if(!self.listening || !self.keySendingEnabled) return;
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_KEY_ADDR;
	[message addFloat:key];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

- (void)sendPrint:(NSString *)print {
	if(!self.listening || !self.printSendingEnabled) return;
	OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = OSC_PRINT_ADDR;
	[message addString:print];
	[connection sendPacket:message toHost:self.sendHost port:self.sendPort];
}

#pragma mark Overridden Getters / Setters

- (void)setSendHost:(NSString *)sendHost {
	_sendHost = sendHost;
	[[NSUserDefaults standardUserDefaults] setObject:sendHost forKey:@"oscSendHost"];
}

- (void)setSendPort:(int)sendPort {
	_sendPort = sendPort;
	[[NSUserDefaults standardUserDefaults] setInteger:sendPort forKey:@"oscSendPort"];
}

- (void)setListenPort:(int)listenPort {
	_listenPort = listenPort;
	[[NSUserDefaults standardUserDefaults] setInteger:listenPort forKey:@"oscListenPort"];
}

- (void)setListening:(BOOL)listening {
	if(_listening == listening) return;
	if(listening) {
		NSError *error;
		if(![connection bindToAddress:nil port:self.listenPort error:&error]) {
			DDLogError(@"OSC: could not bind UDP connection: %@", error);
			_listening = NO;
			return;
		}
		DDLogVerbose(@"OSC: started listening on port %d", connection.localPort);
		[connection receivePacket];
		_listening = YES;
	}
	else {
		DDLogVerbose(@"OSC: stopped listening on port %d", connection.localPort);
		[connection disconnect];
		_listening = NO;
	}
	[[NSUserDefaults standardUserDefaults] setBool:_listening forKey:@"oscServerEnabled"];
}

- (void)setAccelSendingEnabled:(BOOL)accelSendingEnabled {
	_accelSendingEnabled = accelSendingEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:accelSendingEnabled forKey:@"accelSendingEnabled"];
}

- (void)setTouchSendingEnabled:(BOOL)touchSendingEnabled {
	_touchSendingEnabled = touchSendingEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:touchSendingEnabled forKey:@"touchSendingEnabled"];
}

- (void)setLocateSendingEnabled:(BOOL)locateSendingEnabled {
	_locateSendingEnabled = locateSendingEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:locateSendingEnabled forKey:@"locateSendingEnabled"];
}

- (void)setKeySendingEnabled:(BOOL)keySendingEnabled {
	_keySendingEnabled = keySendingEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:keySendingEnabled forKey:@"keySendingEnabled"];
}

- (void)setPrintSendingEnabled:(BOOL)printSendingEnabled {
	_printSendingEnabled = printSendingEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:printSendingEnabled forKey:@"printSendingEnabled"];
}

@end
