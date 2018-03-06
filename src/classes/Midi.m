/*
 * A simple wrapper for CoreMIDI, heavily adapted from PGMidi:
 * https://github.com/petegoodliffe/PGMidi
 *
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * References: http://www.srm.com/qtma/davidsmidispec.html
 *
 */
#import "Midi.h"
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    #import <CoreMIDI/MIDINetworkSession.h>
#endif
#import "Log.h"

#pragma mark - MidiConnection

/// get endpoint name from reference
static NSString *endpointName(MIDIEndpointRef ref) {
	CFStringRef string = nil;
	OSStatus s = MIDIObjectGetStringProperty(ref, kMIDIPropertyDisplayName,
	                                         (CFStringRef *)&string);
	if(s != noErr) {
		return @"Unknown";
	}
	return (__bridge NSString *)string;
}

// returns YES if the endpoint is a virtual session
static BOOL isNetworkSession(MIDIEndpointRef ref) {
	MIDIEntityRef entity = 0;
	MIDIEndpointGetEntity(ref, &entity);
	BOOL hasMidiRtpKey = NO;
	CFPropertyListRef properties = nil;
	OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
	if(s == noErr) {
		NSDictionary *dictionary = (__bridge NSDictionary*)(properties);
		hasMidiRtpKey = [dictionary valueForKey:@"apple.midirtp.session"] != nil;
		CFRelease(properties);
	}
	return hasMidiRtpKey;
}

@interface MidiConnection ()
@property (nonatomic, readwrite) int port;
@end

@implementation MidiConnection

- (instancetype)initWithMidi:(Midi *)midi
                    endpoint:(MIDIEndpointRef)endpoint
                        port:(int)port {
	self = [super init];
	if(self) {
		_midi = midi;
		_endpoint = endpoint;
		_port = port;
		_name = endpointName(endpoint);
		_networkSession = isNetworkSession(endpoint);
	}
	return self;
}

@end

#pragma mark - MidiInput

@implementation MidiInput {
	bool firstPacket;       ///< is this the first received packet?
	bool continueSysex;     ///< is this packet part of a sysex message?
	NSMutableData *message; ///< raw MIDI byte buffer
}

- (instancetype)initWithMidi:(Midi *)midi
                    endpoint:(MIDIEndpointRef)endpoint
                        port:(int)port {
	self = [super initWithMidi:midi endpoint:endpoint port:port];
	if(self) {
		firstPacket = true;
		continueSysex = false;
		message = [NSMutableData new];
	}
	return self;
}

- (void)receiveMessage:(NSData *)message {
	if(self.delegate) {
		[self.delegate midiInput:self receivedMessage:message];
	}
}

#pragma Private

// CoreMIDI callback
static void MIDIReadInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
	@autoreleasepool {
		MidiInput *input = (__bridge MidiInput *)(srcConnRefCon);
		[input midiReceived:pktlist];
	}
}

// CoreMIDI callback
static void MIDIReadVirtualInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
	@autoreleasepool {
		Midi *midi = (__bridge Midi *)readProcRefCon;
		MidiInput *input = midi.virtualInput;
		[input midiReceived:pktlist];
	}
}

// adapted from ofxMidi iOS & RTMidi CoreMIDI message parsing
// called on the MIDI thread, not the main run loop
- (void)midiReceived:(const MIDIPacketList *)packetList {
    const MIDIPacket *packet = &packetList->packet[0];
	unsigned char statusByte;
	unsigned short nBytes, curByte, msgSize;

	for(int i = 0; i < packetList->numPackets; ++i) {
		nBytes = packet->length;
		if(nBytes == 0) {
			continue;
		}
		if(firstPacket) {
			firstPacket = false;
		}

		// handle segmented sysex messages
		curByte = 0;
		if(continueSysex) {

			// copy the packet
			for(int i = 0; i < nBytes; ++i) {
				[message appendBytes:&packet->data[i] length:1];
			}
			continueSysex = packet->data[nBytes-1] != MIDI_SYSEX_END; // look for stop

			if(!continueSysex) {
				// send message if sysex message complete
				if(message.length > 0) {
					[self receiveMessage:message];
				}
				[message setLength:0];
			}
		}
		else { // not sysex, parse bytes
			while(curByte < nBytes) {
				msgSize = 0;

				// next byte in the packet should be a status byte
				statusByte = packet->data[curByte];
				if(!(statusByte & MIDI_NOTE_ON)) {
					break;
				}

				// determine number of bytes in midi message
				if(statusByte < MIDI_PROGRAM_CHANGE) {
					msgSize = 3;
				}
				else if(statusByte < MIDI_PITCH_BEND) {
					msgSize = 2;
				}
				else if(statusByte < MIDI_SYSEX) {
					msgSize = 3;
				}
				else if(statusByte == MIDI_SYSEX) {
					msgSize = nBytes - curByte;
					continueSysex = packet->data[nBytes-1] != MIDI_SYSEX_END;
				}
				else if(statusByte == MIDI_TIME_CODE) {
					msgSize = 2;
				}
				else if(statusByte == MIDI_SONG_POS_POINTER) {
					msgSize = 3;
				}
				else if(statusByte == MIDI_SONG_SELECT) {
					msgSize = 2;
				}
				else { // remaining 1 byte messages: MIDI_START, MIDI_STOP, etc
					msgSize = 1;
				}

				// copy packet
				if(msgSize) {
					[message appendBytes:&packet->data[curByte] length:curByte+msgSize];
					if(!continueSysex) {
						// send message if sysex message complete
						if(message.length > 0) {
							[self receiveMessage:message];
						}
						[message setLength:0];
					}
					curByte += msgSize;
				}
			}
		}
		packet = MIDIPacketNext(packet);
    }
}

@end

#pragma mark - MidiOutput

@implementation MidiOutput

- (void)flush {
	MIDIFlushOutput(self.endpoint);
}

// adapted from PGMidi sendBytes
- (BOOL)sendMessage:(NSData *)message {
	Byte packetBuffer[message.length+100];
	MIDIPacketList *packetList = (MIDIPacketList *)packetBuffer;
	MIDIPacket *packet = MIDIPacketListInit(packetList);
	packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, message.length, message.bytes);
	if(!packet) {
		return NO;
	}
	OSStatus s = MIDISend(self.midi.midiOutputPort, self.endpoint, packetList);
	if(s != noErr) {
		return NO;
	}
	return YES;
}

@end

#pragma mark - Midi

// CoreMIDI callback
static void MIDINotify(const MIDINotification *message, void *refCon);

@interface Midi () {
	MIDIClientRef midiClient;
	MIDIPortRef midiInputPort;
	MIDIPortRef midiOutputPort;
	MIDIEndpointRef virtualInputEndpoint;
	MIDIEndpointRef virtualOutputEndpoint;
	NSTimer *scanTimer;
}
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, readwrite) int maxIO;
@property (nonatomic, strong, readwrite) NSMutableArray *inputs;
@property (nonatomic, strong, readwrite) NSMutableArray *outputs;
@property (nonatomic, readwrite) MidiInput *virtualInput;
@property (nonatomic, readwrite) MidiOutput *virtualOutput;
@end

@implementation Midi

+ (BOOL)available {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 4.2;
#else
	return YES;
#endif
}

+ (void)restart {
	MIDIRestart();
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.name = @"Midi";
		self.maxIO = 16;
		self.inputs = [NSMutableArray new];
		self.outputs = [NSMutableArray new];
		[self setup];
	}
	return self;
}

- (instancetype)initWithName:(NSString *)name andMaxIO:(int)maxIO; {
	self = [super init];
	if(self) {
		self.name = name;
		self.maxIO = maxIO;
		self.inputs = [NSMutableArray new];
		self.outputs = [NSMutableArray new];
		[self setup];
	}
	return self;
}

- (void)setup {
	NSString *clientName = [NSString stringWithFormat:@"%@ Client", self.name];
	OSStatus s = MIDIClientCreate((__bridge CFStringRef)clientName, MIDINotify, (__bridge void*)self, &midiClient);
	if(s != noErr) {
		NSLog(@"Midi: couldn't create client: %d", (int)s);
		return;
	}
	NSString *inputName = [NSString stringWithFormat:@"%@ Input Port", self.name];
	s = MIDIInputPortCreate(midiClient, (__bridge CFStringRef)inputName, MIDIReadInput, (__bridge void*)self, &midiInputPort);
	if(s != noErr) {
		NSLog(@"Midi: couldn't create input port: %d", (int)s);
		return;
	}
	NSString *outputName = [NSString stringWithFormat:@"%@ Output Port", self.name];
	s = MIDIOutputPortCreate(midiClient, (__bridge CFStringRef)outputName, &midiOutputPort);
	if(s != noErr) {
		NSLog(@"Midi: couldn't create output port: %d", (int)s);
		return;
	}
}

- (void)dealloc {
	DDLogVerbose(@"MIDI dealloc");
	self.virtualEnabled = NO;
	self.networkEnabled = NO;
	[scanTimer invalidate];
	[self.inputs removeAllObjects];
	[self.outputs removeAllObjects];
	if(midiInputPort) {
		OSStatus s = MIDIPortDispose(midiInputPort);
		if(s != noErr) {
			NSLog(@"Midi: couldn't delete input port: %d", (int)s);
		}
	}
	if(midiOutputPort) {
		OSStatus s = MIDIPortDispose(midiOutputPort);
		if(s != noErr) {
			NSLog(@"Midi: couldn't delete output port: %d", (int)s);
		}
	}
	if(midiClient) {
		OSStatus s = MIDIClientDispose(midiClient);
		if(s != noErr) {
			NSLog(@"Midi: couldn't delete client: %d", (int)s);
		}
	}
}

- (BOOL)moveInputPort:(int)port toPort:(int)newPort {
	return [Midi movePort:port toPort:newPort inArray:self.inputs];
}

- (BOOL)moveOutputPort:(int)port toPort:(int)newPort {
	return [Midi movePort:port toPort:newPort inArray:self.outputs];
}

#pragma mark Overridden Getters / Setters

- (void)setNetworkEnabled:(BOOL)networkEnabled {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	if(self.inputs.count >= self.maxIO || self.outputs.count >= self.maxIO) {
		return;
	}
	MIDINetworkSession* session = [MIDINetworkSession defaultSession];
	session.enabled = networkEnabled;
	session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
	[self rescan];
#endif
}

- (BOOL)networkEnabled {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	return [MIDINetworkSession defaultSession].enabled;
#else
	return NO;
#endif
}

- (void)setVirtualEnabled:(BOOL)virtualEnabled {
	if(self.virtualEnabled == virtualEnabled) {
		return;
	}
	OSStatus s;
	if(virtualEnabled) {
		if(self.inputs.count >= self.maxIO || self.outputs.count >= self.maxIO) {
			return;
		}

		// create virtual input
		s = MIDISourceCreate(midiClient, (__bridge CFStringRef)self.name, &virtualInputEndpoint);
		if(s != noErr) {
			NSLog(@"Midi: could not create virtual input: %d", (int)s);
			return;
		}
		self.virtualInput = [self connectInput:virtualInputEndpoint];

		// create virtual output
		s = MIDIDestinationCreate(midiClient, (__bridge CFStringRef)self.name, MIDIReadVirtualInput, (__bridge void*)self, &virtualOutputEndpoint);
		if(s != noErr) {
			NSLog(@"Midi: could not create virtual output: %d", (int)s);
			return;
		}

		// set saved virtual ID, otherwise get from endpoint
		SInt32 uniqueID = (SInt32)[[NSUserDefaults standardUserDefaults] integerForKey:@"MidiVirtualOutputID"];
		if(uniqueID) {
			s = MIDIObjectSetIntegerProperty(virtualOutputEndpoint, kMIDIPropertyUniqueID, uniqueID);
			if(s == kMIDIIDNotUnique) {
				uniqueID = 0;
			}
		}
		if(uniqueID == 0) {
			s = MIDIObjectGetIntegerProperty(virtualOutputEndpoint, kMIDIPropertyUniqueID, &uniqueID);
			if(s != noErr) {
				NSLog(@"Midi: could not get virtual output ID: %d", (int)s);
			}
			else {
				[[NSUserDefaults standardUserDefaults] setInteger:uniqueID forKey:@"MidiVirtualOutputID"];
			}
		}
		self.virtualOutput = [self connectOutput:virtualOutputEndpoint];
	}
	else {

		// clear virtual input
		[self disconnectInput:virtualInputEndpoint];
		self.virtualInput = nil;
		s = MIDIEndpointDispose(virtualInputEndpoint);
		if(s != noErr) {
			NSLog(@"Midi: could not delete virtual input: %d", (int)s);
		}
		virtualInputEndpoint = 0;

		// clear virtual output
		[self disconnectOutput:virtualOutputEndpoint];
		self.virtualOutput = nil;
		s = MIDIEndpointDispose(virtualOutputEndpoint);
		if(s != noErr) {
			NSLog(@"Midi: could not delete virtual output: %d", (int)s);
		}
		virtualOutputEndpoint = 0;
	}
}

- (BOOL)virtualEnabled {
	return virtualInputEndpoint && virtualOutputEndpoint;
}

- (MIDIPortRef)midiOutputPort {
	return midiOutputPort;
}

#pragma mark Sending

// try to find the requested port,
// assumes sorted array and counts up from port index
- (BOOL)sendMessage:(NSData *)message toPort:(int)port {
	for(MidiOutput *output in self.outputs) {
		if(output.port == port) {
			return [output sendMessage:message];
		}
		else if(output.port > port) {
			break;
		}
	}
	return NO;
}

- (BOOL)sendMessageToAllPorts:(NSData *)message {
	for(MidiOutput *output in self.outputs) {
		if(![output sendMessage:message]) {
			return NO;
		}
	}
	return YES;
}

- (void)flush {
	for(MidiOutput *output in self.outputs) {
		[output flush];
	}
}

#pragma mark Util

- (MidiInput *)connectInput:(MIDIEndpointRef)endpoint {
	if(self.inputs.count >= self.maxIO) {return nil;}
	MidiInput *input =
		[[MidiInput alloc] initWithMidi:self endpoint:endpoint
									port:[Midi firstAvailablePort:self.inputs]];
	[self.inputs addObject:input];
	[Midi sort:self.inputs];
	if(self.delegate) {
		[self.delegate midi:self inputAdded:input];
	}
	OSStatus s = MIDIPortConnectSource(midiInputPort, endpoint, (__bridge void *)input);
	if(s != noErr) {
		NSLog(@"Midi: could not connect input: %d", (int)s);
    }
	return input;
}

- (MidiOutput *)connectOutput:(MIDIEndpointRef)endpoint {
	if(self.outputs.count >= self.maxIO) {return nil;}
	MidiOutput *output =
		[[MidiOutput alloc] initWithMidi:self endpoint:endpoint
									port:[Midi firstAvailablePort:self.outputs]];
	[self.outputs addObject:output];
	[Midi sort:self.outputs];
	if(self.delegate) {
		[self.delegate midi:self outputAdded:output];
	}
	return output;
}

- (void)disconnectInput:(MIDIEndpointRef)endpoint {
	for(MidiInput *input in self.inputs) {
		if(input.endpoint == endpoint) {
			OSStatus s = MIDIPortDisconnectSource(midiInputPort, endpoint);
			if(s != noErr) {
				NSLog(@"Midi: could not disconnect input: %d", (int)s);
			}
			[self.inputs removeObject:input];
			[Midi sort:self.inputs];
			if(self.delegate) {
				[self.delegate midi:self inputRemoved:input];
			}
			return;
		}
	}
}

- (void)disconnectOutput:(MIDIEndpointRef)endpoint {
	for(MidiOutput *output in self.outputs) {
		if(output.endpoint == endpoint) {
			[self.outputs removeObject:output];
			[Midi sort:self.outputs];
			if(self.delegate) {
				[self.delegate midi:self outputRemoved:output];
			}
			return;
		}
	}
}

- (void)rescan {
	[scanTimer invalidate];
	scanTimer = nil;
	scanTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(scanDevices:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:scanTimer forMode:NSRunLoopCommonModes];
}

/// manually scan for new devices
- (void)scanDevices:(NSTimer *)timer {

	// check for new inputs
	const ItemCount numberOfInputs = MIDIGetNumberOfSources();
	NSMutableArray *removedInputs = [NSMutableArray arrayWithArray:self.inputs];
	for(ItemCount index = 0; index < numberOfInputs; ++index) {
		MIDIEndpointRef endpoint = MIDIGetSource(index);
		BOOL matched = NO;
		for(MidiInput *input in self.inputs) {
			if(input.endpoint == endpoint) {
				[removedInputs removeObject:input];
				matched = YES;
				break;
			}
		}
		if(matched) continue;
		[self connectInput:endpoint];
	}

	// check for new outputs
	const ItemCount numberOfOutputs = MIDIGetNumberOfDestinations();
	NSMutableArray *removedOutputs = [NSMutableArray arrayWithArray:self.outputs];
	for(ItemCount index = 0; index < numberOfOutputs; ++index) {
		MIDIEndpointRef endpoint = MIDIGetDestination(index);
		BOOL matched = NO;
		for(MidiOutput *output in self.outputs) {
			if(output.endpoint == endpoint) {
				[removedOutputs removeObject:output];
				matched = YES;
				break;
			}
		}
		if(matched) continue;
		[self connectOutput:endpoint];
	}

	// remove stale connections
	for(MidiInput *input in removedInputs) {
		[self disconnectInput:input.endpoint];
	}
	for(MidiOutput *output in removedOutputs) {
		[self disconnectOutput:output.endpoint];
	}
}

// returns first available port, assumes array is sorted via index
+ (int)firstAvailablePort:(NSMutableArray *)array {
	for(int i = 0; i < array.count; ++i) {
		MidiConnection *c = array[i];
		if(i != c.port) {
			return i;
		}
	}
	return (int)array.count;
}

// sort via ascending port indices
+ (void)sort:(NSMutableArray *)array {
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"port" ascending:YES];
	[array sortUsingDescriptors:@[sortDescriptor]];
}

// move connection from one port to another, shift the port indices of any
// affected connections and resort
+ (BOOL)movePort:(int)port toPort:(int)newPort inArray:(NSMutableArray *)array {
	if(array.count == 0 || port == newPort || port < 0 || newPort < 0 ||
	   port >= array.count || newPort >= array.count) {
		return NO;
	}

	if(port < newPort) {
		// move port upwards
		BOOL found = NO;
		int p = newPort;
		for(int i = 0; i < array.count; ++i) {
			MidiConnection *c = array[i];

			// find and set new port
			if(c.port < port) continue;
			else if(c.port == port) {
				c.port = newPort;
				found = YES;
				continue;
			}
			else if(!found) {
				return NO;
			}

			// shift ports up to make space
			if(c.port < p) continue;
			else if(c.port == p) {
				c.port++;
				continue;
			}
			else break;
		}
	}
	else {
		// move port downwards
		BOOL found = NO;
		int p = newPort;
		for(int i = (int)array.count-1; i > -1; ++i) {
			MidiConnection *c = array[i];

			// find and set new port
			if(c.port > port) continue;
			else if(c.port == port) {
				c.port = newPort;
				found = YES;
				continue;
			}
			else if(!found) {
				return NO;
			}

			// shift ports down to make space
			if(c.port > p) continue;
			else if(c.port == p) {
				c.port--;
				continue;
			}
			else break;
		}
	}
	[Midi sort:array];
	return YES;
}

#pragma mark Notifications

static void MIDINotify(const MIDINotification *message, void *refCon) {
	Midi *midi = (__bridge Midi*)refCon;
	switch(message->messageID) {
		case kMIDIMsgObjectAdded: {
			MIDIObjectAddRemoveNotification *addremove = (MIDIObjectAddRemoveNotification *)message;
			// swallow generated virtual port addition notifications
			if(addremove->childType == kMIDIObjectType_Source) {
				if(addremove->child == midi->virtualInputEndpoint ) {
					return;
				}
				[midi connectInput:addremove->child];
			}
			if(addremove->childType == kMIDIObjectType_Destination) {
				if(addremove->child == midi->virtualOutputEndpoint ) {
					return;
				}
				[midi connectOutput:addremove->child];
			}
			break;
		}
		case kMIDIMsgObjectRemoved: {
			MIDIObjectAddRemoveNotification *addremove = (MIDIObjectAddRemoveNotification *)message;
			// virtual ports don't seem to generate removal notifications
			if(addremove->childType == kMIDIObjectType_Source) {
				[midi disconnectInput:addremove->child];
			}
			if(addremove->childType == kMIDIObjectType_Destination) {
				[midi disconnectOutput:addremove->child];
			}
			break;
		}
		case kMIDIMsgSetupChanged:
		case kMIDIMsgPropertyChanged:
		case kMIDIMsgThruConnectionsChanged:
		case kMIDIMsgSerialPortOwnerChanged:
		case kMIDIMsgIOError:
			break;
	}
}

@end
