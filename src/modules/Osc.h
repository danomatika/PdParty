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

#define OSC_TOUCH_ADDR	@"/pdparty/touch"
#define OSC_ACCEL_ADDR	@"/pdparty/accelerate"
#define OSC_KEY_ADDR	@"/pdparty/key"
#define OSC_PRINT_ADDR	@"/pdparty/print"

@interface Osc : NSObject <OSCConnectionDelegate>

@property (assign, getter=isListening, nonatomic) BOOL listening;
@property (strong, nonatomic) NSString *sendHost; // do not set when listening
@property (nonatomic) int sendPort; // do not set when listening
@property (nonatomic) int listenPort;

// should the following events be sent automatically? (default: NO)
@property (assign, nonatomic) BOOL accelSendingEnabled;
@property (assign, nonatomic) BOOL touchSendingEnabled;
@property (assign, nonatomic) BOOL keySendingEnabled;
@property (assign, nonatomic) BOOL printSendingEnabled;

#pragma mark Send Events

// send to pdParty osc reciever
- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments;

// rj accel event
- (void)sendAccel:(float)x y:(float)y z:(float)z;

// rj touch event
- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

// pd key event
- (void)sendKey:(int)key;

// pd print event
- (void)sendPrint:(NSString *)print;

@end
