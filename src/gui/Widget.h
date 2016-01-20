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
#import <UIKit/UIKit.h>
#import "PdBase.h"

@class Gui;
@class PdFile;

// defaults
#define WIDGET_FILL_COLOR [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
#define WIDGET_FRAME_COLOR [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]

// for widgets supporting orientation
typedef enum {
	WidgetOrientationHorizontal,
	WidgetOrientationVertical
} WidgetOrientation;

// extended PdListener
@protocol WidgetListener <PdListener>
// implement PdListener methods for recieving bang, float, & symbol
// which are called when lists and messages are receieved
@optional
// receive a [; receiveName set something < message
- (void)receiveSetFloat:(float)received;
- (void)receiveSetSymbol:(NSString *)symbol;
// for forwarding IEM widget edit messages, returns YES if message was handled
- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments;
@end

@class PdDispatcher;

// a widget baseclass
@interface Widget : UIView <WidgetListener>

@property (assign, nonatomic) CGRect originalFrame; // original pd gui object pos & size
@property (assign, nonatomic) CGPoint originalLabelPos; // origin pd label pos (rel to object pos)

@property (strong, nonatomic) UIColor *fillColor;		// IEM gui background
@property (strong, nonatomic) UIColor *frameColor;		// widget outline
@property (strong, nonatomic) UIColor *controlColor;	// IEM gui foreground
// IEM gui label color is at label.textColor

@property (assign, nonatomic) float minValue;
@property (assign, nonatomic) float maxValue;
@property (assign, nonatomic) float value; // base value, Widget is redrawn when set
@property (assign, nonatomic) BOOL inits; // sends value when initing?

@property (strong, nonatomic) NSString *sendName;

// setting this also adds the widget as a listener for pd messages,
// setting to nil removes the widget listener which is important
// as the Widget may not dealloc and you'll get a memory leak since
// the pointer is still being held by the pd dispatcher
// note: this is set to nil in the cleanup: method
@property (strong, nonatomic) NSString *receiveName;

@property (strong, nonatomic) UILabel *label;

// get the widget type as a string, overridden by other widgets
@property (readonly, nonatomic) NSString *type;

// setup any special resources, should be called after widget has been added to
// a parent view *and* the patch has been loaded by libpd
//
// if set, init values are sent when calling this
//
// widgets can laod patch folder resources hre, for instance
- (void)setup;

// replace $0 in atom strings (send, receive, label)
// call this *after* the patch has been loaded or $0 = 0
- (void)replaceDollarZerosForGui:(Gui *)gui fromPatch:(PdFile *)patch;

// reshape based on gui bounds & scale changes
- (void)reshapeForGui:(Gui *)gui;

// cleanup any special resources, should be called before widget will be deleted
//
// clears receiver name from pd dispatcher when called
//
// this is required as some widgets *may* be stored in container objects
// and need to be removed otherwise they may not be dealloc automatically
//
- (void)cleanup;

#pragma mark Sending

// returns true if the widget has a non empty send or recieve name
- (BOOL)hasValidSendName;
- (BOOL)hasValidReceiveName;

// send to objects in pd
- (void)sendBang;
- (void)sendFloat:(float) f;
- (void)sendSymbol:(NSString *)symbol;
- (void)sendList:(NSArray *)list;

// send value if init is set, empty by default
//
// libpd does this automatically for the built-in iem guis,
// subclasses which implement non built-in widgets should implement this
- (void)sendInitValue;

#pragma mark Static Dispatcher

// static recieve dispatcher
+ (PdDispatcher *) dispatcher;
+ (void)setDispatcher:(PdDispatcher *)d;

#pragma mark Number Formatting

// convert a float to a string of the given max length
+ (NSString *)stringFromFloat:(double)f withWidth:(int)width;

@end
