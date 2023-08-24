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
#define PD_KEY_R           @"#key"
#define PD_KEYUP_R         @"#keyup"
#define PD_KEYNAME_R       @"#keyname"
#define PD_OSC_R           @"#osc-in"
#define PD_CLOSEBANG_R     @"#closebang"

// RjDj event receivers
#define RJ_TRANSPORT_R     @"#transport"
#define RJ_VOLUME_R        @"#volume"
#define RJ_MICVOLUME_R     @"#micvolume"
#define RJ_TOUCH_R         @"#touch"
#define RJ_ACCELERATE_R    @"#accelerate"
#define RJ_GYRO_R          @"#gyro"
#define RJ_LOCATION_R      @"#loc"
#define RJ_COMPASS_R       @"#compass"
#define RJ_TIME_R          @"#time"

// touch event types
#define RJ_TOUCH_UP        @"up"
#define RJ_TOUCH_DOWN      @"down"
#define RJ_TOUCH_XY        @"xy"

// PdParty event receivers
#define PARTY_STYLUS_R     @"#stylus"
#define PARTY_MAGNET_R     @"#magnet"
#define PARTY_MOTION_R     @"#motion"
#define PARTY_SPEED_R      @"#speed"
#define PARTY_ALTITUDE_R   @"#altitude"
#define PARTY_CONTROLLER_R @"#controller"
#define PARTY_SHAKE_R      @"#shake"

// incoming event sends
#define PD_OSC_S           @"#osc-out"
#define RJ_GLOBAL_S        @"rjdj"
#define PARTY_GLOBAL_S     @"#pdparty"

// incoming OSC address patterns
#define PARTY_OSC_R        @"pdparty"

// sample rates
#define USER_SAMPLERATE     -1 // user defaults sample rate
#define RJ_SAMPLERATE    22050 // fixed sample rate

#define RECORDINGS_DIR  @"recordings" // in the Documents dir

@class Osc;
@class Sensors;

/// custom dispatcher to grab print events
@interface PureDataDispatcher : PdDispatcher
@property (weak, nonatomic) Osc *osc; ///< pointer to osc instance
@end

/// sensor delegate, used to query whether a sensor is supported & can be started
/// via a #pdparty message
@protocol PdSensorDelegate <NSObject>
- (BOOL)supportsExtendedTouch; ///< not a sensor, per se...
- (BOOL)supportsAccel;
- (BOOL)supportsGyro;
- (BOOL)supportsLocation;
- (BOOL)supportsCompass;
- (BOOL)supportsMagnet;
- (BOOL)supportsMotion;
- (void)touchEverywhere:(BOOL)everywhere; ///< enable #touch over widgets?
@end

/// background event delegate
@protocol PdBackgroundDelegate <NSObject>
- (void)loadBackground:(NSString *)fullpath; ///< load background image
- (void)clearBackground; ///< clear background image
@end

@protocol PdRecordEventDelegate <NSObject>
- (void)remoteRecordingStarted; ///< called if recording is started via a msg
- (void)remoteRecordingFinished; ///< called if recording is stopped via a msg
@end

@interface PureData : NSObject <PdReceiverDelegate, PdMidiReceiverDelegate>

@property (strong, nonatomic) PureDataDispatcher *dispatcher; ///< message dispatcher
@property (weak, nonatomic) Osc *osc; ///< pointer to osc instance
@property (weak, nonatomic) Sensors *sensors; ///< pointer to sensor manager instance

/// enable / disable PD audio processing
@property (getter=isAudioEnabled, nonatomic) BOOL audioEnabled;

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

/// playback audio through the phone earpiece speaker (default: NO)
/// only has effect on iPhone, always NO on iPad or iPod
@property (nonatomic) BOOL earpieceSpeaker;

/// preferred sample rate from current user defaults (default: 48000)
/// does not affect or reflect current sampleRate value
@property (nonatomic) int userSampleRate;

/// calculate the buffer size based on pd's block size:
/// buffer size = ticks per buffer * block size (64)
- (int)calculateBufferSize;

/// calculate the latency in ms: (buffer size / samplerate) * 2
/// 4 tpb * 64 = 256, latency = (256 / 44100) * 2 = ~12 ms
- (int)calculateLatency;

#pragma mark Current Play Values

/// output gate
/// only has effect when [soundoutput] is used
@property (assign, getter=isPlaying, nonatomic) BOOL playing;

/// currently recording to a file?
@property (assign, readonly, getter=isRecording, nonatomic) BOOL recording;

/// input volume, 0-1
/// only has effect when [soundinput] is used
@property (assign, nonatomic) float micVolume;

/// output volume, 0-1
/// only has effect when [soundoutput] is used
@property (assign, nonatomic) float volume;

/// send the current mic volume & play values
- (void)sendCurrentPlayValues;

/// start/stop recording, depends on [soundoutput]
- (void)startRecordingTo:(NSString *)path;
- (void)stopRecording;

/// wrapper around startRecordingTo that creates the recording dir if needed and
/// optionally appends a timestamp string to the filename, returns NO if not started
- (BOOL)startedRecordingToRecordDir:(NSString *)path withTimestamp:(BOOL)timestamp;

/// required for sensor control support queries
@property (assign, nonatomic) id<PdSensorDelegate> sensorDelegate;

/// receives background events
@property (assign, nonatomic) id<PdBackgroundDelegate> backgroundDelegate;

/// receives event when playback is finished
@property (assign, nonatomic) id<PdRecordEventDelegate> recordDelegate;

#pragma mark Send Events

/// rj touch event
+ (void)sendTouch:(NSString *)eventType forIndex:(int)index
       atPosition:(CGPoint)position;

/// pdparty extended touch event
+ (void)sendExtendedTouch:(NSString *)eventType forIndex:(int)index
               atPosition:(CGPoint)position
               withRadius:(float)radius andForce:(float)force;

/// pdparty stylus event, arguments: [radius float azimuth elevation]
+ (void)sendStylus:(NSString *)eventType forIndex:(int)index
        atPosition:(CGPoint)position withArguments:(NSArray *)arguments;

/// rj accel event
+ (void)sendAccel:(float)x y:(float)y z:(float)z;

/// rj gyro event
+ (void)sendGyro:(float)x y:(float)y z:(float)z;

/// rj gps location event
+ (void)sendLocation:(float)lat lon:(float)lon accuracy:(float)accuracy;

/// pdparty gps speed event
+ (void)sendSpeed:(float)speed course:(float)course;

/// pdparty gps altitude event
+ (void)sendAltitude:(float)altitude accuracy:(float)accuracy;

/// rj compass event
+ (void)sendCompass:(float)degrees;

/// rj time event
+ (void)sendTime:(NSArray *)time;

/// droidparty magnet event
+ (void)sendMagnet:(float)x y:(float)y z:(float)z;

/// pdparty motion attitude event
+ (void)sendMotionAttitude:(float)pitch roll:(float)roll yaw:(float)yaw;

/// pdparty motion rotation rate event
+ (void)sendMotionRotation:(float)x y:(float)y z:(float)z;

/// pdparty motion gravity acceleration event
+ (void)sendMotionGravity:(float)x y:(float)y z:(float)z;

/// pdparty motion user acceleration event
+ (void)sendMotionUser:(float)x y:(float)y z:(float)z;

/// pdparty game controller connect/disconnect event
+ (void)sendEvent:(NSString *)event forController:(NSString *)controller;

/// pdparty game controller button event
+ (void)sendController:(NSString *)controller button:(NSString *)button state:(BOOL)state;

/// pdparty game controller axis event
+ (void)sendController:(NSString *)controller axis:(NSString *)axis value:(float)value;

/// pdparty game controller pause event (no state)
+ (void)sendControllerPause:(NSString *)controller;

/// pdparty shake event
+ (void)sendShake;

/// pd key event
+ (void)sendKey:(int)key;

/// pd keyup event
+ (void)sendKeyUp:(int)key;

/// pd keyname event
+ (void)sendKeyName:(NSString *)name pressed:(BOOL)pressed;

/// pd print event
+ (void)sendPrint:(NSString *)print;

/// osc message
+ (void)sendOscMessage:(NSString *)address withArguments:(NSArray *)arguments;

/// [closebang] emulation until libpd supports it ...
+ (void)sendCloseBang;

#pragma mark Send Values

+ (void)sendTransportPlay:(BOOL)play;
+ (void)sendVolume:(float)volume;       ///< [soundoutput] control
+ (void)sendMicVolume:(float)micVolume; ///< [soundinput] control

#pragma mark Find

/// returns YES if an object of a given name current exists in a patch
/// or it's subpatches/abstraction instances, this is using the Pd Find guts
+ (BOOL)objectExists:(NSString *)name inPatch:(PdFile *)patch;

#pragma mark Util

/// generates an rj timestamp array:
/// year, month, day of the month, day of the week, day of the year,
/// time zone, hour, minute, second, millisecond
/// all values are float
+ (NSArray *)timestamp;

@end
