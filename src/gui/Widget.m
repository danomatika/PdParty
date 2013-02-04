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
#import "Widget.h"

#import "Log.h"
#import "PdDispatcher.h"

// suppress leak as we should be fine in ARC
// from http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
#define SuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)

@interface Widget () {}
@property (assign) SEL valueAction;
@property (assign) id valueTarget;
@end

@implementation Widget

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
		self.fillColor = WIDGET_FILL_COLOR;
        self.frameColor = WIDGET_FRAME_COLOR;
		self.controlColor = WIDGET_FRAME_COLOR;
		self.backgroundColor = [UIColor clearColor];
		
		self.minValue = 0.0;
        self.maxValue = 1.0;
		self.value = 0.0;
		self.inits = NO;
	
		self.sendName = @"";
		self.receiveName = @"";
	
		self.label = [[UILabel alloc] initWithFrame:CGRectZero];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.textColor = WIDGET_FRAME_COLOR;
		self.label.textAlignment = UITextAlignmentLeft;
		
		self.valueTarget = nil;
		self.valueAction = nil;
	}
    return self;
}

- (void)dealloc {
	if([self hasValidReceiveName]) {
		[dispatcher removeListener:self forSource:self.receiveName];
	}
}

- (void)addValueTarget:(id)target action:(SEL)action {
	self.valueTarget = target;
	self.valueAction = action;
}

- (BOOL)hasValidSendName {
	return (self.sendName && ![self.sendName isEqualToString:@""]);
}

- (BOOL)hasValidReceiveName {
	return (self.receiveName && ![self.receiveName isEqualToString:@""]);
}

#pragma mark Sending

- (void)send:(NSString*)message {
	if([self hasValidSendName]) {
		[PdBase sendSymbol:message toReceiver:self.sendName];
	}
}

- (void)sendFloat:(float)f {
	if([self hasValidSendName]) {
		[PdBase sendFloat:f toReceiver:self.sendName];
	}
}

- (void)sendInitValue {
	if(self.inits) {
		[self sendFloat:self.value];
	}
}

#pragma mark Overridden Getters & Setters

- (void)setValue:(float)f {
	_value = f;
    if(self.valueTarget) {
        SuppressPerformSelectorLeakWarning(
			[self.valueTarget performSelector:self.valueAction withObject:self]
		);
    }
    [self setNeedsDisplay];
}

- (void)setReceiveName:(NSString *)name {
	if(![name isEqualToString:@""]) {
		[dispatcher removeListener:self forSource:self.receiveName]; // remove old name
		_receiveName = name;
		[dispatcher addListener:self forSource:self.receiveName]; // add new one		
	}
}

- (NSString*)type {
	return @"Widget";
}

#pragma mark Static Dispatcher

static PdDispatcher *dispatcher = nil;

+ (PdDispatcher*)dispatcher {
  return dispatcher;
}

+ (void)setDispatcher:(PdDispatcher*)d {
	dispatcher = d;
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped bang", self.type);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped float", self.type);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped symbol", self.type);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped list", self.type);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	DDLogWarn(@"%@ dropped message", self.type);
}

@end
