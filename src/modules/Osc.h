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
#import "CocoaOSC.h"

#define OSC_TOUCH_ADDR       @"/pdparty/touch"
#define OSC_ACCEL_ADDR       @"/pdparty/accelerate"
#define OSC_GYRO_ADDR        @"/pdparty/gyro"
#define OSC_LOCATION_ADDR    @"/pdparty/loc"
#define OSC_COMPASS_ADDR     @"/pdparty/compass"
#define OSC_TIME_ADDR        @"/pdparty/time"
#define OSC_MAGNET_ADDR      @"/pdparty/magnet"
#define OSC_CONTROLLER_ADDR  @"/pdparty/controller"
#define OSC_KEY_ADDR         @"/pdparty/key"
#define OSC_PRINT_ADDR       @"/pdparty/print"

@interface Osc : NSObject <OSCConnectionDelegate>

@property (readonly, nonatomic) BOOL isListening; //< is the listener running
@property (strong, nonatomic) NSString *sendHost; //< do not set when listening
@property (nonatomic) int sendPort; //< do not set when listening
@property (nonatomic) int listenPort; //< listening port

/// should the following events be sent automatically? (default NO)
@property (assign, nonatomic) BOOL touchSendingEnabled; //< send touch events?
@property (assign, nonatomic) BOOL sensorSendingEnabled; //< accel, gyro, location, compass, magnet
@property (assign, nonatomic) BOOL controllerSendingEnabled; //< send game controller events?
@property (assign, nonatomic) BOOL keySendingEnabled; //< send [key] events?
@property (assign, nonatomic) BOOL printSendingEnabled; //< send pd prints?

/// returns YES if listening was started or the server was already listening,
/// returns NO & sets the error if the server cannot be started
/// note: does *not* restart, you must do that manually
- (BOOL)startListening:(NSError *)error;

/// stops the server
- (void)stopListening;

#pragma mark Send Events

/// send to pdparty osc receiver
- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments;

/// send a raw byte packet to pdparty osc receiver
- (void)sendPacket:(NSData *)data;

/// rj touch event
- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

/// rj accel event
- (void)sendAccel:(float)x y:(float)y z:(float)z;

/// rj gyro event
- (void)sendGyro:(float)x y:(float)y z:(float)z;

/// rj location event
- (void)sendLocation:(float)lat lon:(float)lon accuracy:(float)accuracy;

/// rj compass event
- (void)sendCompass:(float)degrees;

/// rj time event
- (void)sendTime:(NSArray *)time;

/// droid party magnetometer event
- (void)sendMagnet:(float)x y:(float)y z:(float)z;

/// pdparty game controller connect/disconnect event
- (void)sendEvent:(NSString *)event forController:(NSString *)controller;

/// pdparty game controller button event
- (void)sendController:(NSString *)controller button:(NSString *)button state:(BOOL)state;

/// pdparty game controller axis event
- (void)sendController:(NSString *)controller axis:(NSString *)axis value:(float)value;

/// pdparty game controller pause event (no state)
- (void)sendControllerPause:(NSString *)controller;

/// pd key event
- (void)sendKey:(int)key;

/// pd print event
- (void)sendPrint:(NSString *)print;

@end
