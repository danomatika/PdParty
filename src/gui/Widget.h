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

// defaults
#define WIDGET_FILL_COLOR [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
#define WIDGET_FRAME_COLOR [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]

@class PdDispatcher;

@interface Widget : UIView <PdListener>

@property (assign) CGRect originalFrame; // original pd gui object pos & size
@property (assign) CGPoint originalLabelPos; // origin pd label pos (rel to object pos)

@property (strong) UIColor *fillColor;		// IEM gui background
@property (strong) UIColor *frameColor;		// widget outline
@property (strong) UIColor *controlColor;	// IEM gui foreground
// IEM gui label color is at label.textColor

@property (assign) float minValue;
@property (assign) float maxValue;
@property (assign, nonatomic) float value;
@property (assign) BOOL inits; // sends value when initing?

@property (strong) NSString *sendName;
@property (strong, nonatomic) NSString *receiveName;

@property (strong, nonatomic) UILabel *label;

// get the widget type as a string, overridden by other widgets
@property (readonly, nonatomic) NSString *type;

// reshape based on gui bounds & scale changes
- (void)reshapeForGui:(Gui *)gui;

// static receieve dispatcher
+ (PdDispatcher*) dispatcher;
+ (void)setDispatcher:(PdDispatcher*)d;

// set a selector and method to perform when the widget's value is changed
- (void)addValueTarget:(id)target action:(SEL)action;

// returns true if the widget has a non empty send or recieve name
- (BOOL)hasValidSendName;
- (BOOL)hasValidReceiveName;

// send to objects in pd
- (void)send:(NSString*) message;
- (void)sendFloat:(float) f;

// send an init val if init is set
- (void)sendInitValue;

@end
