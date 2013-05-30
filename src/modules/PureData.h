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
#import "PdBase.h"
#import "PdFile.h"
#import "PdDispatcher.h"

// PD event receivers
#define PD_KEY_R		@"#key"

// RjDj event receivers
#define RJ_TRANSPORT_R	@"#transport"
#define RJ_ACCELERATE_R	@"#accelerate"
#define RJ_VOLUME_R		@"#volume"
//#define RJ_MICVOLUME_R	@"#micvolume"
#define RJ_TOUCH_R		@"#touch"

// touch event types
#define RJ_TOUCH_UP		@"up"
#define RJ_TOUCH_DOWN	@"down"
#define RJ_TOUCH_XY		@"xy"

// PdPaty event receivers
#define PARTY_ROTATE_R	@"#rotate"

// rotate event orientations
#define PARTY_ORIENT_PORTRAIT				@"portrait"
#define PARTY_ORIENT_PORTRAIT_UPSIDEDOWN	@"upsidedown"
#define PARTY_ORIENT_LANDSCAPE_LEFT			@"landleft"
#define PARTY_ORIENT_LANDSCAPE_RIGHT		@"landright"

// sample rates
#define PARTY_SAMPLERATE	44100
#define RJ_SAMPLERATE		22050

@class Midi;

@interface PureData : NSObject <PdMidiReceiverDelegate>

@property (strong, nonatomic) PdDispatcher *dispatcher; // message dispatcher
@property (weak, nonatomic) Midi *midi; // pointer to midi instance

// enabled / disable PD audio
@property (getter=isAudioEnabled) BOOL audioEnabled;

// setting the sample rate re-configures the audio, 44100 by default
// new sample rate ignored if it is equal to the current samplerate
@property (nonatomic) int sampleRate;

#pragma mark Send Events

// pd key event
+ (void)sendKey:(int)key;

// rj touch event
+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

// rj accel event
+ (void)sendAccel:(float)x y:(float)y z:(float)z;

// pdparty rotate event
+ (void)sendRotate:(float)degrees newOrientation:(NSString *)orientation;

// rj style transport control
+ (void)sendPlay:(BOOL)playing;

// rj style input/output volume controls
+ (void)sendVolume:(float)vol;

@end
