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
#import <Foundation/Foundation.h>

#import "PdBase.h"
#import "PdDispatcher.h"

@class Midi;

@interface PureData : NSObject <PdMidiReceiverDelegate>

@property (nonatomic, strong) PdDispatcher *dispatcher; // message dispatcher
@property (nonatomic, weak) Midi *midi; // pointer to midi instance

// enabled / disable PD audio
@property (getter=isAudioEnabled) BOOL audioEnabled;

@end
