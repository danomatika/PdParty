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

#import "lo/lo.h"
#import "Log.h"
#import "PureData.h"

//#define DEBUG_OSC

// liblo C callbacks
void errorCB(int num, const char *msg, const char *where);
int messageCB(const char *path, const char *types, lo_arg **argv,
              int argc, lo_message msg, void *user_data);

@interface Osc () {
	lo_server_thread server;
	lo_address sendAddress;
}
@property (readwrite, nonatomic) BOOL isListening;
@end

@implementation Osc

- (id)init {
	self = [super init];
	if(self) {
		server = NULL;
		sendAddress = NULL;
		
		NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
		
		_sendHost = [defaults objectForKey:@"oscSendHost"];
		_sendPort = (int)[defaults integerForKey:@"oscSendPort"];
		_listenPort = (int)[defaults integerForKey:@"oscListenPort"];
		_listenGroup = [defaults objectForKey:@"oscListenGroup"];

		self.touchSendingEnabled = [defaults boolForKey:@"touchSendingEnabled"];
		self.sensorSendingEnabled = [defaults boolForKey:@"sensorSendingEnabled"];
		self.controllerSendingEnabled = [defaults boolForKey:@"controllerSendingEnabled"];
		self.shakeSendingEnabled = [defaults boolForKey:@"shakeSendingEnabled"];
		self.keySendingEnabled = [defaults boolForKey:@"keySendingEnabled"];
		self.printSendingEnabled = [defaults boolForKey:@"printSendingEnabled"];
		
		// should start listening if saved
		if([defaults boolForKey:@"oscServerEnabled"]) {
			[self start];
		}
	}
	return self;
}

- (void)dealloc {
	if(self.isListening) {
		[self stop];
	}
}

- (BOOL)start {
	if(![self updateSendAddress]) {
		return NO;
	}
	if(![self updateServer]) {
		return NO;
	}
	self.isListening = YES;
	LogVerbose(@"Osc: started listening on port %d", lo_server_thread_get_port(server));
	LogVerbose(@"Osc: sending to %s on port %s", lo_address_get_hostname(sendAddress), lo_address_get_port(sendAddress));

	return YES;
}

- (void)stop {
	if(server) {
		lo_server_thread_stop(server);
		lo_server_thread_free(server);
		server = NULL;
		LogVerbose(@"OSC: stopped listening");
	}
	self.isListening = NO;

	if(sendAddress) {
		lo_address_free(sendAddress);
		sendAddress = NULL;
	}
}

- (BOOL)startListening {
	if(self.isListening) return YES; // still listening
	BOOL ret = [self start];
	[NSUserDefaults.standardUserDefaults setBool:self.isListening forKey:@"oscServerEnabled"];
	return ret;
}

- (void)stopListening {
	if(!self.isListening) return;
	[self stop];
	[NSUserDefaults.standardUserDefaults setBool:NO forKey:@"oscServerEnabled"];
}

#pragma mark Receive Events

- (void)receiveMessage:(NSString *)address withArguments:(NSArray *)arguments {
	#ifdef DEBUG_OSC
		LogVerbose(@"OSC message to %@: %@", address, [arguments description]);
	#endif
	[PureData sendOscMessage:address withArguments:arguments];
}

#pragma mark Send Events

- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments {
	if(!self.isListening) return;
	lo_message m = lo_message_new();
	for(NSObject *o in arguments) {
		if([o isKindOfClass:NSNumber.class]) {
			lo_message_add_float(m, [(NSNumber *)o floatValue]);
		}
		else if([o isKindOfClass:NSString.class]) {
			lo_message_add_string(m, [(NSString *)o UTF8String]);
		}
		else {
			LogWarn(@"Osc: dropping non-numeric/string argument: %@", o);
		}
	}
	if(lo_send_message(sendAddress, [address UTF8String], m) < 0) {
		int err = lo_address_errno(sendAddress);
		const char *errstr = lo_address_errstr(sendAddress);
		LogError(@"OSC: couldn't send message: %d %s", err, errstr);
	}
	lo_message_free(m);
}

- (void)sendPacket:(NSData *)data {
	if(!self.isListening) return;
	if(!data || data.length < 1 || !data.bytes) {
		return;
	}
	char firstByte = ((char *)data.bytes)[0];
	if(firstByte == '/') {
		int res = 0;
		lo_message m = lo_message_deserialise((void *)data.bytes, data.length, &res);
		if(res != 0) {
			LogError(@"Osc: couldn't send packet: parsing failed, error %d", res);
			lo_message_free(m);
			return;
		}
		char *path = lo_get_path((void *)data.bytes, data.length);
		if(lo_send_message(sendAddress, path, m) < 0) {
			int err = lo_address_errno(sendAddress);
			const char *errstr = lo_address_errstr(sendAddress);
			LogError(@"OSC: couldn't send packet: %d %s", err, errstr);
		}
		lo_message_free(m);
	}
	else if(firstByte == '#') {
		LogWarn(@"Osc: couldn't send packet: bundle not supported");
	}
	else {
		LogWarn(@"Osc: couldn't send packet: unrecognized first byte '%c'", firstByte);
	}
}

- (void)sendTouch:(NSString *)eventType forIndex:(int)index
       atPosition:(CGPoint)position {
	if(!self.isListening || !self.touchSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "siff", [eventType UTF8String], index, position.x, position.y);
	lo_send_message(sendAddress, [OSC_TOUCH_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendExtendedTouch:(NSString *)eventType forIndex:(int)index
               atPosition:(CGPoint)position
               withRadius:(float)radius andForce:(float)force {
	if(!self.isListening || !self.touchSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "siffff", [eventType UTF8String], index, position.x, position.y, radius, force);
	lo_send_message(sendAddress, [OSC_TOUCH_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendStylus:(NSString *)eventType forIndex:(int)index
        atPosition:(CGPoint)position withArguments:(NSArray *)arguments {
	if(!self.isListening || !self.touchSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "siffffff", [eventType UTF8String], index, position.x, position.y,
		[arguments[0] floatValue], [arguments[1] floatValue],
		[arguments[2] floatValue], [arguments[3] floatValue]);
	lo_send_message(sendAddress, [OSC_STYLUS_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendAccel:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "fff", x, y, z);
	lo_send_message(sendAddress, [OSC_ACCEL_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendGyro:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "fff", x, y, z);
	lo_send_message(sendAddress, [OSC_GYRO_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendLocation:(float)lat lon:(float)lon accuracy:(float)accuracy {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "fff", lat, lon, accuracy);
	lo_send_message(sendAddress, [OSC_LOCATION_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendSpeed:(float)speed course:(float)course {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "ff", speed, course);
	lo_send_message(sendAddress, [OSC_SPEED_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendAltitude:(float)altitude accuracy:(float)accuracy {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "ff", altitude, accuracy);
	lo_send_message(sendAddress, [OSC_ALTITUDE_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendCompass:(float)degrees {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add_float(m, degrees);
	lo_send_message(sendAddress, [OSC_COMPASS_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendTime:(NSArray *)time {
	if(!self.isListening) return;
	[self sendMessage:OSC_TIME_ADDR withArguments:time];
}

- (void)sendMagnet:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "fff", x, y, z);
	lo_send_message(sendAddress, [OSC_MAGNET_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendMotionAttitude:(float)pitch roll:(float)roll yaw:(float)yaw {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sfff", "attitude", pitch, roll, yaw);
	lo_send_message(sendAddress, [OSC_MOTION_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendMotionRotation:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sfff", "rotation", x, y, z);
	lo_send_message(sendAddress, [OSC_MOTION_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendMotionGravity:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sfff", "gravity", x, y, z);
	lo_send_message(sendAddress, [OSC_MOTION_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendMotionUser:(float)x y:(float)y z:(float)z {
	if(!self.isListening || !self.sensorSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sfff", "user", x, y, z);
	lo_send_message(sendAddress, [OSC_MOTION_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendEvent:(NSString *)event forController:(NSString *)controller {
	if(!self.isListening || !self.controllerSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "ss", [event UTF8String], [controller UTF8String]);
	lo_send_message(sendAddress, [OSC_CONTROLLER_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendController:(NSString *)controller button:(NSString *)button state:(BOOL)state {
	if(!self.isListening || !self.controllerSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sssf", [controller UTF8String], "button", [button UTF8String], (float)state);
	lo_send_message(sendAddress, [OSC_CONTROLLER_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendController:(NSString *)controller axis:(NSString *)axis value:(float)value {
	if(!self.isListening || !self.controllerSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sssf", [controller UTF8String], "axis", [axis UTF8String], value);
	lo_send_message(sendAddress, [OSC_CONTROLLER_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendControllerPause:(NSString *)controller {
	if(!self.isListening || !self.controllerSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "ss", [controller UTF8String], "pause");
	lo_send_message(sendAddress, [OSC_CONTROLLER_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendShake {
	if(!self.isListening || !self.shakeSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_send_message(sendAddress, [OSC_SHAKE_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendKey:(int)key {
	if(!self.isListening || !self.keySendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add_float(m, key);
	lo_send_message(sendAddress, [OSC_KEY_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendKeyUp:(int)key {
	if(!self.isListening || !self.keySendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add_float(m, key);
	lo_send_message(sendAddress, [OSC_KEYUP_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendKeyName:(NSString *)name pressed:(BOOL)pressed {
	if(!self.isListening || !self.keySendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add(m, "sf", [name UTF8String], (float)pressed);
	lo_send_message(sendAddress, [OSC_KEYNAME_ADDR UTF8String], m);
	lo_message_free(m);
}

- (void)sendPrint:(NSString *)print {
	if(!self.isListening || !self.printSendingEnabled) return;
	lo_message m = lo_message_new();
	lo_message_add_string(m, [print UTF8String]);
	lo_send_message(sendAddress, [OSC_PRINT_ADDR UTF8String], m);
	lo_message_free(m);
}

#pragma mark Overridden Getters / Setters

- (void)setSendHost:(NSString *)sendHost {
	_sendHost = sendHost;
	if([self updateSendAddress]) {
		LogVerbose(@"Osc: sending to %s on port %s", lo_address_get_hostname(sendAddress), lo_address_get_port(sendAddress));
	}
	[NSUserDefaults.standardUserDefaults setObject:sendHost forKey:@"oscSendHost"];
}

- (void)setSendPort:(int)sendPort {
	_sendPort = sendPort;
	if([self updateSendAddress]) {
		LogVerbose(@"Osc: sending to %s on port %s", lo_address_get_hostname(sendAddress), lo_address_get_port(sendAddress));
	}
	[NSUserDefaults.standardUserDefaults setInteger:sendPort forKey:@"oscSendPort"];
}

- (void)setListenPort:(int)listenPort {
	_listenPort = listenPort;
	if([self updateServer]) {
		LogVerbose(@"Osc: listening on port %d", lo_server_thread_get_port(server));
	}
	[NSUserDefaults.standardUserDefaults setInteger:listenPort forKey:@"oscListenPort"];
}

- (void)setListenGroup:(NSString *)listenGroup {
	_listenGroup = listenGroup;
	if([self updateServer]) {
		if(![listenGroup isEqualToString:@""]) {
			LogVerbose(@"Osc: listening on multicast group %@", listenGroup);
		}
	}
	[NSUserDefaults.standardUserDefaults setObject:listenGroup forKey:@"oscListenGroup"];
}

- (void)setTouchSendingEnabled:(BOOL)touchSendingEnabled {
	_touchSendingEnabled = touchSendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:touchSendingEnabled forKey:@"touchSendingEnabled"];
}

- (void)setSensorSendingEnabled:(BOOL)sensorSendingEnabled {
	_sensorSendingEnabled = sensorSendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:sensorSendingEnabled forKey:@"sensorSendingEnabled"];
}

- (void)setControllerSendingEnabled:(BOOL)controllerSendingEnabled {
	_controllerSendingEnabled = controllerSendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:controllerSendingEnabled forKey:@"controllerSendingEnabled"];
}

- (void)setShakeSendingEnabled:(BOOL)shakeSendingEnabled {
	_shakeSendingEnabled = shakeSendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:shakeSendingEnabled forKey:@"shakeSendingEnabled"];
}

- (void)setKeySendingEnabled:(BOOL)keySendingEnabled {
	_keySendingEnabled = keySendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:keySendingEnabled forKey:@"keySendingEnabled"];
}

- (void)setPrintSendingEnabled:(BOOL)printSendingEnabled {
	_printSendingEnabled = printSendingEnabled;
	[NSUserDefaults.standardUserDefaults setBool:printSendingEnabled forKey:@"printSendingEnabled"];
}

#pragma mark Private

- (BOOL)updateSendAddress {
	if(sendAddress) {
		lo_address_free(sendAddress);
	}
	NSString *port = [NSString stringWithFormat:@"%d", self.sendPort];
	sendAddress = lo_address_new([self.sendHost UTF8String], [port UTF8String]);
	if(!sendAddress) {
		LogError(@"Osc: could not create send address");
		return NO;
	}
	return YES;
}

- (BOOL)updateServer {
	if(server) {
		lo_server_thread_stop(server);
		lo_server_thread_free(server);
	}
	NSString *port = [NSString stringWithFormat:@"%d", self.listenPort];
	if([self.listenGroup isEqualToString:@""]) {
		server = lo_server_thread_new([port UTF8String], *errorCB);
	}
	else {
		server = lo_server_thread_new_multicast([self.listenGroup UTF8String], [port UTF8String], *errorCB);
	}
	if(!server) {
		LogError(@"Osc: could not create server");
		return NO;
	}
	lo_server_thread_add_method(server, NULL, NULL, *messageCB, (__bridge const void *)(self));
	lo_server_thread_start(server);
	return YES;
}

@end

#pragma mark liblo C callbacks

void errorCB(int num, const char *msg, const char *where) {
	NSMutableString *s = [[NSMutableString alloc] initWithFormat:@"OSC: liblo server thread error %d", num];
	if(msg) {[s appendFormat:@" : %s", msg];}     // might be NULL
	if(where) {[s appendFormat:@" : %s", where];} // might be NULL
	LogError(@"%@", s);
}

int messageCB(const char *path, const char *types, lo_arg **argv,
              int argc, lo_message msg, void *user_data) {
	Osc *osc = (__bridge Osc *)user_data;
	NSMutableArray *args = [NSMutableArray array];
	for(int i = 0; i < argc; ++i) {
		char type = types[i];
		switch (type) {
		
			// strings & chars
			case LO_STRING:
				[args addObject:[NSString stringWithUTF8String:&argv[i]->s]];
				break;
			case LO_SYMBOL:
				[args addObject:[NSString stringWithUTF8String:&argv[i]->S]];
				break;
			case LO_CHAR:
				[args addObject:[NSString stringWithFormat:@"%c", argv[i]->c]];
				break;
				
			// numbers
			case LO_INT32:
				[args addObject:[NSNumber numberWithInt:argv[i]->i]];
				break;
			case LO_INT64:
				[args addObject:[NSNumber numberWithLongLong:argv[i]->h]];
				break;
			case LO_FLOAT:
				[args addObject:[NSNumber numberWithFloat:argv[i]->f]];
				break;
			case LO_DOUBLE:
				[args addObject:[NSNumber numberWithDouble:argv[i]->d]];
				break;
			
			// drop the rest for now
			default:
				break;
		}
	}
	[osc receiveMessage:[NSString stringWithUTF8String:path] withArguments:args];
	return 0;
}
