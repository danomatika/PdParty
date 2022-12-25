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
#import "MidiBridge.h"

#import "Log.h"
#import "PdBase.h"
#import "Util.h"

// verbose prints for testing MIDI IO
//#define DEBUG_MIDI

@interface MidiBridge () {
	NSMutableData *message;
	NSTimer *connectionEventTimer;
}
@property (nonatomic, strong) Midi *midi; ///< underlying midi object
@end

@implementation MidiBridge

- (id)init {
	self = [super init];
	if(self) {
		message = [NSMutableData data];

		NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
		_multiDeviceMode = [defaults boolForKey:@"multiMidiDeviceMode"];
		self.enabled = [defaults boolForKey:@"midiEnabled"];
	}
	return self;
}

- (void)dealloc {
	[connectionEventTimer invalidate];
	self.midi.delegate = nil;
}

- (BOOL)moveInputPort:(int)port toPort:(int)newPort {
	return [self.midi moveInputPort:port toPort:newPort];
}

- (BOOL)moveOutputPort:(int)port toPort:(int)newPort {
	return [self.midi moveOutputPort:port toPort:newPort];
}

#pragma mark Overridden Getters / Setters

- (void)setEnabled:(BOOL)enabled {
	if(self.enabled == enabled) {
		return;
	}
	NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
	if(enabled) {
		if([Midi available]) {
			LogVerbose(@"MidiBridge: midi enabled");
			self.midi = nil;
			self.midi = [[Midi alloc] initWithName:@"PdParty" andMaxIO:MIDI_MAX_IO];
			self.midi.delegate = self;
			self.midi.virtualEnabled = [defaults boolForKey:@"virtualMidiEnabled"];
			self.midi.networkEnabled = [defaults boolForKey:@"networkMidiEnabled"];
			[defaults setBool:YES forKey:@"midiEnabled"];
		}
		else {
			LogWarn(@"MidiBridge: sorry, your OS version does not support CoreMIDI");
		}
	}
	else {
		self.midi.delegate = nil;
		self.midi = nil;
		[defaults setBool:NO forKey:@"midiEnabled"];
		LogVerbose(@"MidiBridge: midi disabled");
	}
}

- (BOOL)enabled {
	return self.midi != nil;
}

- (void)setNetworkEnabled:(BOOL)networkEnabled {
	if(!self.midi || self.midi.networkEnabled == networkEnabled) {
		return;
	}
	self.midi.networkEnabled = networkEnabled;
	[NSUserDefaults.standardUserDefaults setBool:self.midi.networkEnabled forKey:@"networkMidiEnabled"];
}

- (BOOL)networkEnabled {
	return self.midi.networkEnabled;
}

- (void)setVirtualEnabled:(BOOL)virtualEnabled {
	if(!self.midi || self.midi.virtualEnabled == virtualEnabled) {
		return;
	}
	self.midi.virtualEnabled = virtualEnabled;
	[NSUserDefaults.standardUserDefaults setBool:self.midi.virtualEnabled forKey:@"virtualMidiEnabled"];
}

- (BOOL)virtualEnabled {
	return self.midi.virtualEnabled;
}

- (void)setMultiDeviceMode:(BOOL)multiDeviceMode {
	if(_multiDeviceMode == multiDeviceMode) {
		return;
	}
	_multiDeviceMode = multiDeviceMode;
	[NSUserDefaults.standardUserDefaults setBool:_multiDeviceMode forKey:@"multiMidiDeviceMode"];
}

- (NSArray *)inputs {
	return self.midi.inputs;
}

- (NSArray *)outputs {
	return self.midi.outputs;
}

#pragma mark PGMidiDelegate

-(void)midi:(Midi *)midi inputAdded:(MidiInput *)input {
	input.delegate = self;
	[self connectionEventReceived];
	LogVerbose(@"MidiBridge: input added: \"%@\"", input.name);
}

- (void)midi:(Midi *)midi inputRemoved:(MidiInput *)input {
	input.delegate = nil;
	[self connectionEventReceived];
	LogVerbose(@"MidiBridge: input removed: \"%@\"", input.name);
}

- (void)midi:(Midi *)midi outputAdded:(MidiOutput *)output {
	[self connectionEventReceived];
	LogVerbose(@"MidiBridge: output added: \"%@\"", output.name);
}

- (void)midi:(Midi *)midi outputRemoved:(MidiOutput *)output {
	[self connectionEventReceived];
	LogVerbose(@"MidiBridge: output removed: \"%@\"", output.name);
}

#pragma mark MidiInputDelegate

- (void)midiInput:(MidiInput *)input receivedMessage:(NSData *)message {
	const unsigned char *bytes = (const unsigned char *)[message bytes];
	int statusByte = bytes[0];
	int channel = 0;
	int port = (self.multiDeviceMode ? input.port : 0);

	if(bytes[0] >= MIDI_SYSEX) {
		statusByte = bytes[0] & 0xFF;
	}
	else {
		statusByte = bytes[0] & 0xF0;
		channel = (int) (bytes[0] & 0x0F);
		if(self.multiDeviceMode) {
			// add port offset
			channel += port * 16;
		}
	}

	#ifdef DEBUG_MIDI
		[Util logData:message withHeader:[NSString stringWithFormat:@"MidiBridge: input %d received ", input.port]];
	#endif

	// send message to appropriate object: [notein], [ctlin], [pgmin], etc
	switch(statusByte) {
		case MIDI_NOTE_ON:
			[PdBase sendNoteOn:channel pitch:bytes[1] velocity:bytes[2]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received Note On %d %d %d", channel, bytes[1], bytes[2]);
			#endif
			break;
		case MIDI_NOTE_OFF: // ignore velocity a pd uses vel 0 to indicate note off
			[PdBase sendNoteOn:channel pitch:bytes[1] velocity:0];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received Note Off %d %d %d -> 0", channel, bytes[1], bytes[2]);
			#endif
			break;
		case MIDI_CONTROL_CHANGE: {
			[PdBase sendControlChange:channel controller:bytes[1] value:bytes[2]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received Control %d %d %d", channel, bytes[1], bytes[2]);
			#endif
			break;
		}
		case MIDI_PROGRAM_CHANGE:
			[PdBase sendProgramChange:channel value:bytes[1]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received Program %d %d", channel, bytes[1]);
			#endif
			break;
		case MIDI_PITCH_BEND: {
			int value = (bytes[2] << 7) + bytes[1]; // msb + lsb
			value -= 8192; // convert range from 0 - 16384 to libpd -8192 - 8192
			[PdBase sendPitchBend:channel value:value];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received PitchBend %d %d", channel, value);
			#endif
			break;
		}
		case MIDI_AFTERTOUCH:
			[PdBase sendAftertouch:channel value:bytes[1]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received Aftertouch %d %d", channel, bytes[1]);
			#endif
			break;
		case MIDI_POLY_AFTERTOUCH:
			[PdBase sendPolyAftertouch:channel pitch:bytes[1] value:bytes[2]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received PolyAftertouch %d %d %d", channel, bytes[1], bytes[2]);
			#endif
			break;
		case MIDI_SYSEX:
			for(int i = 0; i < message.length; ++i) {
				[PdBase sendSysex:channel byte:bytes[i]];
			}
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received %d Sysex bytes to %d", (int)message.length, channel);
			#endif
			break;
		case MIDI_TIME_CLOCK: case MIDI_START: case MIDI_CONTINUE: case MIDI_STOP:
		case MIDI_ACTIVE_SENSING: case MIDI_SYSTEM_RESET:
			[PdBase sendSysRealTime:port byte:bytes[0]];
			#ifdef DEBUG_MIDI
				LogVerbose(@"MidiBridge: received %d Realtime bytes", (int)message.length);
			#endif
			return; // realtime bytes do not go to [midiin]
		default:
			break;
	}

	// send raw byte data to [midiin]
	for(int i = 0; i < message.length; ++i) {
		[PdBase sendMidiByte:port byte:bytes[i]];
	}
}

#pragma mark PdMidiReceiverDelegate

- (void)receiveNoteOn:(int)pitch withVelocity:(int)velocity forChannel:(int)channel {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending Note %d %d %d", channel, pitch, velocity);
	#endif
	[message setLength:3];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_NOTE_ON+channel;
	bytes[1] = pitch;
	bytes[2] = velocity;
	[self sendMessage:message toPort:port];
}

- (void)receiveControlChange:(int)value forController:(int)controller forChannel:(int)channel {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending Control %d %d %d", channel, controller, value);
	#endif
	[message setLength:3];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_CONTROL_CHANGE+channel;
	bytes[1] = controller;
	bytes[2] = value;
	[self sendMessage:message toPort:port];
}

- (void)receiveProgramChange:(int)value forChannel:(int)channel {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending Program %d %d", channel, value);
	#endif
	[message setLength:2];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_PROGRAM_CHANGE+channel;
	bytes[1] = value;
	[self sendMessage:message toPort:port];
}

- (void)receivePitchBend:(int)value forChannel:(int)channel {
	value += 8192; // convert range from libpd -8192 - 8192 to 0 - 16384
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending PitchBend %d %d", channel, value);
	#endif
	[message setLength:3];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_PITCH_BEND+channel;
	bytes[1] = value & 0x7F; // lsb 7bit
	bytes[2] = (value >> 7) & 0x7F; // msb 7bit
	[self sendMessage:message toPort:port];
}

- (void)receiveAftertouch:(int)value forChannel:(int)channel {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending Aftertouch %d %d", channel, value);
	#endif
	[message setLength:2];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_AFTERTOUCH+channel;
	bytes[1] = value;
	[self sendMessage:message toPort:port];
}

- (void)receivePolyAftertouch:(int)value forPitch:(int)pitch forChannel:(int)channel {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending PolyAftertouch %d %d %d", channel, pitch, value);
	#endif
	[message setLength:3];
	int port = 0;
	if(channel >= 16) {
		port = channel / 16;
		channel = channel % 16;
	}
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = MIDI_POLY_AFTERTOUCH+channel;
	bytes[1] = pitch;
	bytes[2] = value;
	[self sendMessage:message toPort:port];
}

- (void)receiveMidiByte:(int)byte forPort:(int)port {
	#ifdef DEBUG_MIDI
		LogVerbose(@"MidiBridge: sending Midi byte %02X", byte);
	#endif
	[message setLength:1];
	unsigned char *bytes = (unsigned char *)[message bytes];
	bytes[0] = byte;
	[self sendMessage:message toPort:port];
}

#pragma mark Private

- (void)sendMessage:(NSData *)message toPort:(int)port {
	#ifdef DEBUG_MIDI
		[Util logData:message withHeader:[NSString stringWithFormat:@"MidiBridge: sending"]];
	#endif
	if(self.multiDeviceMode) {
		[self.midi sendMessage:message toPort:port];
	}
	else {
		[self.midi sendMessageToAllPorts:message];
	}
}

// use timer to smooth lots of events for UI
- (void)connectionEventReceived {
	[connectionEventTimer invalidate];
	connectionEventTimer = nil;
	connectionEventTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(notifyChange:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:connectionEventTimer forMode:NSRunLoopCommonModes];
}

- (void)notifyChange:(NSTimer *)timer {
	if(self.delegate) {
		[self.delegate midiConnectionsChanged];
	}
	timer = nil;
}

@end
