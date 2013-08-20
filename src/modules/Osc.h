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

#define OSC_TOUCH_ADDR	@"/pd/touch"
#define OSC_ACCEL_ADDR	@"/pd/accelerate"
#define OSC_ROTATE_ADDR	@"/pd/rotate"
#define OSC_KEY_ADDR	@"/pd/key"

@interface Osc : NSObject <OSCConnectionDelegate>

@property (assign, getter=isListening, nonatomic) BOOL listening;
@property (strong, nonatomic) NSString *sendHost; // do not set when listening
@property (nonatomic) int sendPort; // do not set when listening
@property (nonatomic) int listenPort;

// should the following events be sent automatically? (default: NO)
@property (assign, nonatomic) BOOL accelSendingEnabled;
@property (assign, nonatomic) BOOL touchSendingEnabled;
@property (assign, nonatomic) BOOL rotationSendingEnabled;
@property (assign, nonatomic) BOOL keySendingEnabled;

#pragma mark Send Events

// send to pdParty osc reciever
- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments;

// rj accel event
- (void)sendAccel:(float)x y:(float)y z:(float)z;

// rj touch event
- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

// pdparty rotate event
- (void)sendRotate:(float)degrees newOrientation:(NSString *)orientation;

// pd key event
- (void)sendKey:(int)key;

@end
