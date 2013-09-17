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
- (void)midiSourceConnectionEvent; // a source has been added or removed
- (void)midiDestinationConnectionEvent; // a destination has been added or removed
@end

@interface Midi : NSObject <PGMidiDelegate, PGMidiSourceDelegate>

// enabled midi in/out?
@property (getter=isEnabled, nonatomic) BOOL enabled;

// enable Core Midi networking session
@property (getter=isNetworkEnabled, nonatomic) BOOL networkEnabled;

@property (strong, nonatomic) PGMidi *midi; // underlying pgmidi object
@property (assign, nonatomic) id<MidiConnectionDelegate> delegate;

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
