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
#define OSC_LOCATE_ADDR @"/pdparty/locate"
#define OSC_HEADING_ADDR @"/pdparty/heading"
#define OSC_KEY_ADDR	@"/pdparty/key"
#define OSC_PRINT_ADDR	@"/pdparty/print"

@interface Osc : NSObject <OSCConnectionDelegate>

@property (readonly, nonatomic) BOOL isListening;
@property (strong, nonatomic) NSString *sendHost; // do not set when listening
@property (nonatomic) int sendPort; // do not set when listening
@property (nonatomic) int listenPort;

// should the following events be sent automatically? (default: NO)
@property (assign, nonatomic) BOOL accelSendingEnabled;
@property (assign, nonatomic) BOOL touchSendingEnabled;
@property (assign, nonatomic) BOOL locateSendingEnabled;
@property (assign, nonatomic) BOOL headingSendingEnabled;
@property (assign, nonatomic) BOOL keySendingEnabled;
@property (assign, nonatomic) BOOL printSendingEnabled;

// returns YES if listening was started or the server was already listening,
// returns NO & sets the error if the server cannot be started
// note: does *not* restart, you must do that manually
- (BOOL)startListening:(NSError *)error;

// stops the server
- (void)stopListening;

#pragma mark Send Events

// send to pdParty osc receiver
- (void)sendMessage:(NSString *)address withArguments:(NSArray *)arguments;

// send a raw byte packet to pdParty osc receiver
- (void)sendPacket:(NSData *)data;

// rj accel event
- (void)sendAccel:(float)x y:(float)y z:(float)z;

// rj touch event
- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(float)x andY:(float)y;

// pd party locate event
- (void)sendLocate:(float)lat lon:(float)lon alt:(float)alt
	speed:(float)speed  course:(float)course
	horzAccuracy:(float)horzAccuracy vertAccuracy:(float)vertAccuracy
	timestamp:(NSString *)timestamp;

// pd party heading event
- (void)sendHeading:(float)degrees accuracy:(float)accuracy timestamp:(NSString *)timestamp;

// pd key event
- (void)sendKey:(int)key;

// pd print event
- (void)sendPrint:(NSString *)print;

@end
