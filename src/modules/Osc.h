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

#define OSC_TOUCH_ADDR	@"/pd/event/touch"
#define OSC_ACCEL_ADDR	@"/pd/event/accelerate"
#define OSC_ROTATE_ADDR	@"/pd/event/rotate"
#define OSC_OSC_ADDR	@"/pd/event/osc"

@interface Osc : NSObject <OSCConnectionDelegate>

@property (nonatomic, getter=isListening) BOOL listening;
@property (nonatomic, strong) NSString *sendHost; // do not set when listening
@property (nonatomic) int sendPort; // do not set when listening
@property (nonatomic) int listenPort;

#pragma mark Send Events

// send to pdParty osc reciever
- (void)sendBang;
- (void)sendFloat:(float)f;
- (void)sendSymbol:(NSString *)symbol;
- (void)sendList:(NSArray *)list;

// rj touch event
- (void)sendTouch:(NSString *)eventType forId:(int)id atX:(int)x andY:(int)y;

// rj accel event
- (void)sendAccel:(float)x y:(float)y z:(float)z;

// pdparty rotate event
- (void)sendRotate:(float)degrees newOrientation:(NSString *)orientation;

@end
