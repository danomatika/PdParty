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

@interface Midi : NSObject <PGMidiDelegate, PGMidiSourceDelegate>

// create a new interface, sets up PGMidi, etc
+ (id)interface;

// enable Core Midi networking session
- (void)enableNetwork:(bool)enabled;

// source / destination hot plugging
- (void)midi:(PGMidi*)midi sourceAdded:(PGMidiSource *)source;
- (void)midi:(PGMidi*)midi sourceRemoved:(PGMidiSource *)source;
- (void)midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination;
- (void)midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination;

// midi input message ignores
@property bool bIgnoreSysex;
@property bool bIgnoreTiming;
@property bool bIgnoreSense;

// receiving
- (void)midiSource:(PGMidiSource *)input midiReceived:(const MIDIPacketList *)packetList;

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
