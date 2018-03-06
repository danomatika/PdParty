/*
 * A simple wrapper for CoreMIDI, heavily adapted from PGMidi:
 * https://github.com/petegoodliffe/PGMidi
 *
 * Copyright (c) 2013, 2018 Dan Wilcox <danomatika@gmail.com>
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
#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

// MIDI status bytes
enum MidiStatus {

	// channel voice messages       # data bytes
	MIDI_NOTE_OFF           = 0x80, // 2
	MIDI_NOTE_ON            = 0x90, // 2
	MIDI_POLY_AFTERTOUCH    = 0xA0, // 2, aka key pressure
	MIDI_CONTROL_CHANGE     = 0xB0, // 2
	MIDI_PROGRAM_CHANGE     = 0xC0, // 1
	MIDI_AFTERTOUCH         = 0xD0, // 1, aka channel pressure
	MIDI_PITCH_BEND         = 0xE0, // 2

	// system common messages
	MIDI_SYSEX              = 0xF0, // variable, until SYSEX_END
	MIDI_TIME_CODE          = 0xF1, // 1
	MIDI_SONG_POS_POINTER   = 0xF2, // 2
	MIDI_SONG_SELECT        = 0xF3, // 1
	MIDI_TUNE_REQUEST       = 0xF6, // -
	MIDI_SYSEX_END          = 0xF7, // -

	// realtime messages
	MIDI_TIME_CLOCK         = 0xF8, // -
	MIDI_START              = 0xFA, // -
	MIDI_CONTINUE           = 0xFB, // -
	MIDI_STOP               = 0xFC, // -
	MIDI_ACTIVE_SENSING     = 0xFE, // -
	MIDI_SYSTEM_RESET       = 0xFF  // -
};

// number range defines
// because it's sometimes hard to remember these...
#define MIDI_MIN_BEND 0
#define MIDI_MAX_BEND 16383

@class Midi;
@class MidiInput;

#pragma mark MidiConnection

/// a generic MIDI connection
@interface MidiConnection : NSObject

/// parent reference
@property (nonatomic, weak, readonly) Midi *midi;

/// CoreMIDI endpoint
@property (nonatomic, readonly) MIDIEndpointRef endpoint;

/// assigned port index, based on first available
@property (nonatomic, readonly) int port;

/// device endpoint name
@property (nonatomic, readonly) NSString *name;

/// is this a network session? (iOS only)
@property (nonatomic, readonly) BOOL networkSession;

/// init connection with required parent, endpoint, and port index
- (instancetype)initWithMidi:(Midi *)midi
                    endpoint:(MIDIEndpointRef)endpoint
					    port:(int)port;

@end

#pragma mark MidiInput

/// midi connection event delegate, called on MIDI thread so make sure
/// to do any GUI updates on the main thread
@protocol MidiInputDelegate <NSObject>
- (void)midiInput:(MidiInput *)input receivedMessage:(NSData *)message;
@end

/// a MIDI input
@interface MidiInput : MidiConnection

/// input delegate
@property (nonatomic, weak) id<MidiInputDelegate> delegate;

/// receive and forward a complete MIDI message to delegate
- (void)receiveMessage:(NSData *)message;

@end

#pragma mark MidiOutput

/// a MIDI output
@interface MidiOutput : MidiConnection

/// send a complete MIDI message
- (BOOL)sendMessage:(NSData *)message;

/// flush any remaining bytes
- (void)flush;

@end

#pragma mark Midi

/// midi connection event delegate
@protocol MidiDelegate <NSObject>
- (void)midi:(Midi *)midi inputAdded:(MidiInput *)input;
- (void)midi:(Midi *)midi inputRemoved:(MidiInput *)input;
- (void)midi:(Midi *)midi outputAdded:(MidiOutput *)output;
- (void)midi:(Midi *)midi outputRemoved:(MidiOutput *)output;
@end

/// CoreMIDI wrapper and input parser, handles MIDI device connections
///
/// inputs and outputs are added automatically and assigned port indices
/// based on their order of appearance, disconnected indices are reused
/// when new devices appear
@interface Midi : NSObject

/// called when new connections are made
@property (nonatomic, weak) id<MidiDelegate> delegate;

/// enable Core Midi networking session? (iOS only)
@property (nonatomic) BOOL networkEnabled;

/// enable virtual input & output ports?
/// iOS: requires adding the background audio mode capability
@property (nonatomic) BOOL virtualEnabled;

/// name used for client and virtual ports
@property (nonatomic, readonly) NSString *name;

/// maximum number of allowed MidiInput & MidiOutput pairs,
/// including virtual and network ports (default 16)
/// ie. max of 10 limits to 10 inputs & 10 outputs
@property (nonatomic, readonly) int maxIO;

/// current MidiInputs
@property (nonatomic, readonly) NSMutableArray *inputs;

/// current MidiOutputs
@property (nonatomic, readonly) NSMutableArray *outputs;

/// virtual MidiInput, nil if not enabled
@property (nonatomic, readonly) MidiInput *virtualInput;

/// virtual MidiOutput, nil if not enabled
@property (nonatomic, readonly) MidiOutput *virtualOutput;

/// CoreMIDI output port for sending
@property (nonatomic, readonly) MIDIPortRef midiOutputPort;

/// returns YES if CoreMIDI is available
+ (BOOL)available;

/// ask CoreMIDI to restart all connected devices
+ (void)restart;

/// init with generic client name and default number of allowed IO
- (instancetype)init;

/// init with specified client name and number of allowed IO
- (instancetype)initWithName:(NSString *)name andMaxIO:(int)maxIO;

/// send raw MIDI byte message to an output port
- (BOOL)sendMessage:(NSData *)message toPort:(int)port;

/// send raw MIDI byte message to all output ports
- (BOOL)sendMessageToAllPorts:(NSData *)message;

/// flush any remaining bytes on all output ports
- (void)flush;

/// move input at given port index to a new port index and shift input ports
/// does nothing if there is no input at port index, returns YES on success
- (BOOL)moveInputPort:(int)port toPort:(int)newPort;

/// move output at given port index to a new port index and shift output ports
/// does nothing if there is no input at port index, returns YES on success
- (BOOL)moveOutputPort:(int)port toPort:(int)newPort;

@end
