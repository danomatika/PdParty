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
#define PD_KEY_R        @"#key"
#define PD_OSC_R        @"#osc-in"
#define PD_CLOSEBANG_R  @"#closebang"

// RjDj event receivers
#define RJ_TRANSPORT_R  @"#transport"
#define RJ_VOLUME_R     @"#volume"
#define RJ_MICVOLUME_R  @"#micvolume"
#define RJ_TOUCH_R      @"#touch"
#define RJ_ACCELERATE_R @"#accelerate"
#define RJ_GYRO_R       @"#gyro"
#define RJ_LOCATION_R   @"#loc"
#define RJ_COMPASS_R    @"#compass"
#define RJ_TIME_R       @"#time"

// touch event types
#define RJ_TOUCH_UP     @"up"
#define RJ_TOUCH_DOWN   @"down"
#define RJ_TOUCH_XY     @"xy"

// PdParty event receivers
#define PARTY_MAGNET_R  @"#magnet"

// incoming event sends
#define PD_OSC_S        @"#osc-out"
#define RJ_GLOBAL_S     @"rjdj"
#define PARTY_GLOBAL_S  @"#pdparty"

// incoming OSC address patterns
#define PARTY_OSC_R     @"pdparty"

// sample rates
#define PARTY_SAMPLERATE 44100
#define RJ_SAMPLERATE    22050

#define RECORDINGS_DIR  @"recordings" //< in the Documents dir

@class Midi;
@class Osc;
@class Sensors;

/// custom dispatcher to grab print events
@interface PureDataDispatcher : PdDispatcher
@property (weak, nonatomic) Osc *osc; //< pointer to osc instance
@end

/// sensor delegate used to query whether a sensor is supported & can be started
/// via a #pdparty message
@protocol PdSensorSupportDelegate <NSObject>
- (BOOL)supportsAccel;
- (BOOL)supportsGyro;
- (BOOL)supportsLocation;
- (BOOL)supportsCompass;
- (BOOL)supportsMagnet;
@end

@protocol PdRecordEventDelegate <NSObject>
- (void)remoteRecordingStarted; //< called if recording is started via a msg
- (void)remoteRecordingFinished; //< called if recording is stopped via a msg
- (void)playbackFinished; //< called when a wav file playback finished & looping is disabled
@end

@interface PureData : NSObject <PdReceiverDelegate, PdMidiReceiverDelegate>

@property (strong, nonatomic) PureDataDispatcher *dispatcher; //< message dispatcher
@property (weak, nonatomic) Midi *midi; //< pointer to midi instance
@property (weak, nonatomic) Osc *osc; //< pointer to osc instance
@property (weak, nonatomic) Sensors *sensors; //< pointer to sensor manager instance

/// enabled / disable PD audio processing
@property (getter=isAudioEnabled) BOOL audioEnabled;

/// setting the sample rate re-configures the audio, 44100 by default
/// new sample rate ignored if it is equal to the current samplerate
@property (nonatomic) int sampleRate;

/// set to YES to have the latency (ticks per buffer) chosen automatically,
/// otherwise the ticks per buffer will always be set when changing sampleRates,
/// YES by default
@property (nonatomic) BOOL autoLatency;

/// setting the ticks per buffer sets the buffer size / audio latency
/// range is 1 - 32, 16 by default
@property (nonatomic) int ticksPerBuffer;

/// calculate the buffer size based on pd's block size:
/// buffer size = ticks per buffer * block size (64)
- (int)calculateBufferSize;

/// calculate the latency in ms: (buffer size / samplerate) * 2
/// 4 tpb * 64 = 256, latency = (256 / 44100) * 2 = 11.6 ms
- (float)calculateLatency;

#pragma mark Current Play Values

/// only has effect when [soundoutput] is used
@property (assign, getter=isPlaying, nonatomic) BOOL playing;
@property (assign, getter=isLooping, nonatomic) BOOL looping; //< playback

@property (assign, readonly, getter=isRecording, nonatomic) BOOL recording;
@property (assign, readonly, getter=isPlayingback, nonatomic) BOOL playingback;

/// input/output volume, 0-1
/// only has effect when [soundinput]/[soundoutput] are used
@property (assign, nonatomic) float micVolume;
@property (assign, nonatomic) float volume;

/// send the current volume & playing values
- (void)sendCurrentPlayValues;

/// start/stop recording, depends on [soundoutput]
- (void)startRecordingTo:(NSString *)path;
- (void)stopRecording;

/// wrapper around startRecordingTo that creates the recording dir if needed and
/// optionally appends a timestamp string to the filename, returns NO if not started
- (BOOL)startedRecordingToRecordDir:(NSString *)path withTimestamp:(BOOL)timestamp;

/// start/stop playback, opens playback.pd
- (void)startPlaybackFrom:(NSString *)path;
- (void)stopPlayback;

/// receives event when playback is finished
@property (assign, nonatomic) id<PdRecordEventDelegate> recordDelegate;

/// required for sensor control support queries
@property (assign, nonatomic) id<PdSensorSupportDelegate> sensorDelegate;

#pragma mark Send Events

/// rj touch event
+ (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

/// rj accel event
+ (void)sendAccel:(float)x y:(float)y z:(float)z;

/// rj gyro event
+ (void)sendGyro:(float)x y:(float)y z:(float)z;

/// rj location event
+ (void)sendLocation:(float)lat lon:(float)lon accuracy:(float)accuracy;

/// rj compass event
+ (void)sendCompass:(float)degrees;

/// rj time event
+ (void)sendTime:(NSArray *)time;

/// droid party gyro event
+ (void)sendMagnet:(float)x y:(float)y z:(float)z;

/// pd key event
+ (void)sendKey:(int)key;

/// pd print event
+ (void)sendPrint:(NSString *)print;

/// osc message
+ (void)sendOscMessage:(NSString *)address withArguments:(NSArray *)arguments;

/// [closebang] emulation until libpd supports it ...
+ (void)sendCloseBang;

#pragma mark Send Values

+ (void)sendTransportPlay:(BOOL)play;
+ (void)sendTransportLoop:(BOOL)loop; //< playback only

+ (void)sendVolume:(float)volume; //< used for playback

#pragma mark Find

/// returns true if an object of a given name current exists in a patch
/// or it's subpatches/abstraction instances, this is using the Pd Find guts
+ (BOOL)objectExists:(NSString *)name inPatch:(PdFile *)patch;

#pragma mark Util

/// generates an rj timestamp array:
/// year, month, day of the month, day of the week, day of the year,
/// time zone, hour, minute, second, millisecond
/// all values are float
+ (NSArray *)timestamp;

@end
