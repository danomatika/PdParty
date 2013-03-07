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

// PD event receivers
#define PD_KEY_R		@"#key"

// RjDj event receivers
#define RJ_TRANSPORT_R	@"#transport"
#define RJ_ACCELERATE_R	@"#accelerate"
#define RJ_MICVOLUME_R	@"#micvolume"
#define RJ_TOUCH_R		@"#touch"

// touch event types
#define RJ_TOUCH_UP		@"up"
#define RJ_TOUCH_DOWN	@"down"
#define RJ_TOUCH_XY		@"xy"

@class Midi;

@interface PureData : NSObject <PdMidiReceiverDelegate>

@property (nonatomic, strong) PdDispatcher *dispatcher; // message dispatcher
@property (nonatomic, weak) Midi *midi; // pointer to midi instance

// enabled / disable PD audio
@property (getter=isAudioEnabled) BOOL audioEnabled;

#pragma mark Send Events

// pd key event
+ (void)sendKey:(int)key;

// rj touch event
+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(int)x andY:(int)y;

// rj accel event
+ (void)sendAccelWithX:(float)x y:(float)y z:(float)z;

@end
