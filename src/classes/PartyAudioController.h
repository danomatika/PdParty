/*
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PdAudioController.h"

/// pd audio controller with audio session option overrides
@interface PartyAudioController : PdAudioController

/// playback audio through the phone earpiece speaker (default: NO)
/// only has effect on iPhone, always NO on iPad or iPod
@property (assign, nonatomic) BOOL earpieceSpeaker;

// overridden to add extra options
- (AVAudioSessionCategoryOptions)playAndRecordOptions;

@end
