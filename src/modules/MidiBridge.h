/*
 * Copyright (c) 2013, 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "Midi.h"
#import "PdBase.h"

/// midi connection event delegate
@protocol MidiBridgeDelegate <NSObject>
- (void)midiConnectionsChanged;  ///< MIDI inputs and/or outputs have changed
@end

/// MIDI bridge to PureData
@interface MidiBridge : NSObject <MidiDelegate, MidiInputDelegate, PdMidiReceiverDelegate>

/// called when new connections are made
@property (nonatomic, weak) id<MidiBridgeDelegate> delegate;

/// enabled midi in/out?
@property (nonatomic) BOOL enabled;

/// enable CoreMIDI networking session?
@property (nonatomic) BOOL networkEnabled;

/// enable virtual connections?
@property (nonatomic) BOOL virtualEnabled;

/// multiple device mode: add channel offset based on port number (default NO)
/// ie. port 0: 1-16, port 1: 17-32, port 2: 33-48, port 4: 49-64
/// all devices share channels 1-16 when NO
@property (nonatomic) BOOL multiDeviceMode;

/// MidiInput & MidiOutput array access, nil when not enabled
@property (nonatomic, readonly) NSArray *inputs;
@property (nonatomic, readonly) NSArray *outputs;

@end
