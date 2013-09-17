/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
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
#import "PGMidi.h"

// midi connection event delegate
@protocol MidiConnectionDelegate <NSObject>
- (void)midiInputConnectionEvent; // an input has been added or removed
- (void)midiOutputConnectionEvent; // an output has been added or removed
@end

@interface Midi : NSObject <PGMidiDelegate, PGMidiSourceDelegate>

// called when new connections are made
@property (assign, nonatomic) id<MidiConnectionDelegate> delegate;

// enabled midi in/out?
@property (getter=isEnabled, nonatomic) BOOL enabled;

// enable Core Midi networking session
@property (getter=isNetworkEnabled, nonatomic) BOOL networkEnabled;

// enable virtual connections
@property (getter=isVirtualInputEnabled, nonatomic) BOOL virtualInputEnabled;
@property (getter=isVirtualOutputEnabled, nonatomic) BOOL virtualOutputEnabled;

// PGMidiSource & PGMidiDestination array acess
@property (weak, readonly, nonatomic) NSArray *inputs;
@property (weak, readonly, nonatomic) NSArray *outputs;

// midi input message ignores
@property bool bIgnoreSysex;
@property bool bIgnoreTiming;
@property bool bIgnoreSense;

// sending
- (void)sendNoteOn:(int)channel pitch:(int)pitch velocity:(int)velocity;
- (void)sendControlChange:(int)channel controller:(int)controller value:(int)value;
- (void)sendProgramChange:(int)channel value:(int)value;
- (void)sendPitchBend:(int)channel value:(int)value;
- (void)sendAftertouch:(int)channel value:(int)value;
- (void)sendPolyAftertouch:(int)channel pitch:(int)pitch value:(int)value;
- (void)sendMidiByte:(int)port byte:(int)byte;
- (void)sendSysex:(int)port byte:(int)byte;

@end
