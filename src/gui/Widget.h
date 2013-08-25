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
// for forwarding IEM widget edit messages
- (void)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments;
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
@property (assign, nonatomic) float value;
@property (assign, nonatomic) BOOL inits; // sends value when initing?

@property (strong) NSString *sendName;
@property (strong, nonatomic) NSString *receiveName;

@property (strong, nonatomic) UILabel *label;

// get the widget type as a string, overridden by other widgets
@property (readonly, nonatomic) NSString *type;

// replace $0 in atom strings (send, receive, label)
// call this *after* the patch has been loaded or $0 = 0
- (void)replaceDollarZerosForGui:(Gui *)gui fromPatch:(PdFile *)patch;

// reshape based on gui bounds & scale changes
- (void)reshapeForGui:(Gui *)gui;

#pragma mark Sending

// returns true if the widget has a non empty send or recieve name
- (BOOL)hasValidSendName;
- (BOOL)hasValidReceiveName;

// send to objects in pd
- (void)send:(NSString *)message;
- (void)sendFloat:(float) f;
- (void)sendBang;

// send an init val if init is set
- (void)sendInitValue;

#pragma mark Static Dispatcher

// static receieve dispatcher
+ (PdDispatcher *) dispatcher;
+ (void)setDispatcher:(PdDispatcher *)d;

#pragma mark Number Formatting

// convert a float to a string of the given max length
+ (NSString *)stringFromFloat:(double)f withWidth:(int)width;

@end
