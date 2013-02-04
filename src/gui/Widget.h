/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#import <UIKit/UIKit.h>
#import "PdBase.h"

#define WIDGET_FILL_COLOR [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
#define WIDGET_FRAME_COLOR [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]

@class PdDispatcher;

@interface Widget : UIView <PdListener>

@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *frameColor;

@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float value;
@property (nonatomic, assign) BOOL inits; // sends value when initing?

@property (nonatomic, retain) NSString *sendName;
@property (nonatomic, retain) NSString *receiveName;

@property (nonatomic, retain) UILabel *label;

// get the widget type as a string, overridden by other widgets
@property (nonatomic, readonly) NSString *type;

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
