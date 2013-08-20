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
#define PD_OSC_R		@"#osc-in"
#define PD_OSC_S		@"#osc-out"

// RjDj event receivers
#define RJ_TRANSPORT_R	@"#transport"
#define RJ_ACCELERATE_R	@"#accelerate"
#define RJ_VOLUME_R		@"#volume"
#define RJ_MICVOLUME_R	@"#micvolume"
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
@class Osc;

@interface PureData : NSObject <PdReceiverDelegate, PdMidiReceiverDelegate>

@property (strong, nonatomic) PdDispatcher *dispatcher; // message dispatcher
@property (weak, nonatomic) Midi *midi; // pointer to midi instance
@property (weak, nonatomic) Osc *osc; // pointer to osc instance

// enabled / disable PD audio processing
@property (getter=isAudioEnabled) BOOL audioEnabled;

// setting the sample rate re-configures the audio, 44100 by default
// new sample rate ignored if it is equal to the current samplerate
@property (nonatomic) int sampleRate;

#pragma mark Current Play Values

// only has effect when [soundoutput] is used
@property (assign, getter=isPlaying, nonatomic) BOOL playing;
@property (assign, readonly, getter=isRecording, nonatomic) BOOL recording;

// input/output volume, 0-1
// only has effect when [soundinput]/[soundoutput] are used
@property (assign, nonatomic) float micVolume;
@property (assign, nonatomic) float volume;

// send the current volume & playing values
- (void)sendCurrentPlayValues;

// start/stop recording, depends on [soundoutput]
- (void)startRecordingTo:(NSString *)path;
- (void)stopRecording;

#pragma mark Send Events

// rj touch event
+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

// rj accel event
+ (void)sendAccel:(float)x y:(float)y z:(float)z;

// pdparty rotate event
+ (void)sendRotate:(float)degrees newOrientation:(NSString *)orientation;

// pd key event
+ (void)sendKey:(int)key;

// osc message
+ (void)sendOscMessage:(NSString *)address withArguments:(NSArray *)arguments;

#pragma mark Send Values

+ (void)sendTransportPlay:(BOOL)play;

+ (void)sendMicVolume:(float)micVolume;
+ (void)sendVolume:(float)volume;

@end
