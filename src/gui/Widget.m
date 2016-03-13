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
#import "Widget.h"

#import "Gui.h"
#import "PdFile.h"
#import "PdDispatcher.h"

@implementation Widget

// private init
- (void)_init {
	self.originalFrame = CGRectZero;
	self.originalLabelPos = CGPointZero;

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
	self.label.textAlignment = NSTextAlignmentLeft;
	[self addSubview:self.label];
}

- (id)init {
	self = [super init];
	if(self) {
		[self _init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		[self _init];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		[self _init];
	}
	return self;
}

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	self = [super initWithFrame:CGRectZero];
	if(self) {
		[self _init];
		self.gui = gui;
	}
	return self;
}

- (void)dealloc {
	[self cleanup]; // just in case
}

- (void)setup {
	if(self.inits) {
		[self sendInitValue];
	}
}

// override if label shouldn't replace $0 or #0
- (void)replaceDollarZerosForGui:(Gui *)gui fromPatch:(PdFile *)patch {
	self.sendName = [gui replaceDollarZeroStringsIn:self.sendName fromPatch:patch];
	self.receiveName = [gui replaceDollarZeroStringsIn:self.receiveName fromPatch:patch];
	self.label.text = [gui replaceDollarZeroStringsIn:self.label.text fromPatch:patch];
}

// override for custom redraw
- (void)reshape {
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * self.gui.scaleX),
		round(self.originalFrame.origin.y * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleX),
		round(self.originalFrame.size.height * self.gui.scaleX));
}

- (void)cleanup {
	self.receiveName = nil; // make sure widget is removed from pd dispatcher
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	DDLogVerbose(@"%@: dropped bang", self.type);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogVerbose(@"%@: dropped float", self.type);
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogVerbose(@"%@: dropped symbol", self.type);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 0) {
	
		// pass float through, setting the value
		if([list isNumberAt:0]) {
			[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
		}
		else if([list isStringAt:0]) {
			// if we receive a set message
			if([[list objectAtIndex:0] isEqualToString:@"set"]) {
				NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, list.count-1)];
				[self receiveEditMessage:[list objectAtIndex:1] withArguments:[list objectsAtIndexes:set]];
			}
			else if([[list objectAtIndex:0] isEqualToString:@"bang"]) { // got a bang!
				[self receiveBangFromSource:source];
			}
			else { // pass symbol through, setting the value
				[self receiveSymbol:[list objectAtIndex:0] fromSource:source];
			}
		}
	}
	else {
		DDLogVerbose(@"%@: dropped list", self.type);
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {

	// set message sets value without sending
	if([message isEqualToString:@"set"] && arguments.count == 1) {
		if([arguments isNumberAt:0]) {
			[self receiveSetFloat:[[arguments objectAtIndex:0] floatValue]];
		}
		else if([arguments isStringAt:0]) {
			[self receiveSetSymbol:[arguments objectAtIndex:0]];
		}
	}
	else if([message isEqualToString:@"bang"]) { // got a bang!
		[self receiveBangFromSource:source];
	}
	else { // everything else
		if(![self receiveEditMessage:message withArguments:arguments]) {
			DDLogVerbose(@"%@: dropped message: %@", self.type, message);
		}
	}
}

- (void)receiveSetFloat:(float)received {
	DDLogVerbose(@"%@: dropped set float", self.type);
}

- (void)receiveSetSymbol:(NSString *)symbol {
	DDLogVerbose(@"%@: dropped set symbol", self.type);
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	DDLogVerbose(@"%@: dropped edit message", self.type);
	return NO;
}

#pragma mark Sending

- (BOOL)hasValidSendName {
	return (self.sendName && ![self.sendName isEqualToString:@""]);
}

- (BOOL)hasValidReceiveName {
	return (self.receiveName && ![self.receiveName isEqualToString:@""]);
}

- (void)sendBang {
	if([self hasValidSendName]) {
		[PdBase sendBangToReceiver:self.sendName];
	}
}

- (void)sendFloat:(float)f {
	if([self hasValidSendName]) {
		[PdBase sendFloat:f toReceiver:self.sendName];
	}
}

- (void)sendSymbol:(NSString *)symbol {
	if([self hasValidSendName]) {
		[PdBase sendSymbol:symbol toReceiver:self.sendName];
	}
}

- (void)sendList:(NSArray *)list {
	if([self hasValidSendName]) {
		[PdBase sendList:list toReceiver:self.sendName];
	}
}

- (void)sendInitValue {}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	_value = f;
	[self setNeedsDisplay];
}

- (void)setReceiveName:(NSString *)name {
	if([_receiveName isEqualToString:name]) {
		return;
	}
	if([self hasValidReceiveName]) {
		[dispatcher removeListener:self forSource:self.receiveName]; // remove old name
	}
	_receiveName = name;
	if(name && ![name isEqualToString:@""]) {
		[dispatcher addListener:self forSource:self.receiveName]; // add new one
	}
}

- (NSString *)type {
	return @"Widget";
}

#pragma mark Static Dispatcher

static PdDispatcher *dispatcher = nil;

+ (PdDispatcher *)dispatcher {
  return dispatcher;
}

+ (void)setDispatcher:(PdDispatcher *)d {
	dispatcher = d;
}

#pragma mark Number Formatting

// adapted from void my_numbox_ftoa(t_my_numbox *x) in g_numbox.c
+ (NSString *)stringFromFloat:(double)f withWidth:(int)width {

	BOOL is_exp = NO;
	int i, idecimal;
	NSMutableString *string = [NSMutableString stringWithFormat:@"%g", f];
	
	// if it is in exponential mode
	if(string.length >= 5) {
		i = (int)string.length - 4;
		if(([string characterAtIndex:i] == 'e') || ([string characterAtIndex:i] == 'E'))
			is_exp = YES;
	}
	
	// if to reduce
	if(string.length > width) {
		if(is_exp) {
			if(width <= 5) {
				[string setString:(f < 0.0 ? @"-" : @"+")];
			}
			i = (int)string.length - 4;
			for(idecimal = 0; idecimal < i; idecimal++) {
				if([string characterAtIndex:idecimal] == '.') {
					break;
				}
			}
			if(idecimal > (width - 4)){
				[string setString:(f < 0.0 ? @"-" : @"+")];
			}
			else {
				int new_exp_index = width-4, old_exp_index = (int)string.length-4;
				// check index here since original algorithm was designed for a
				// fixed length string buffer and simply moved the null terminator around,
				// but we're using a dynamic length Obj-C string
				if(old_exp_index > -1) {
					for(i = 0; i < 4; i++, new_exp_index++, old_exp_index++) {
						[string setCharacter:[string characterAtIndex:old_exp_index] atIndex:new_exp_index];
					}
					[string deleteCharactersInRange:NSMakeRange(width, string.length-width)];
				}
			}
		}
		else {
			for(idecimal = 0; idecimal < (int)string.length; idecimal++) {
				if([string characterAtIndex:idecimal] == '.') {
					break;
				}
			}
			if(idecimal > width) {
				[string setString:(f < 0.0 ? @"-" : @"+")];
			}
			else {
				[string deleteCharactersInRange:NSMakeRange(width, string.length-width)];
			}
		}
	}
	return string;
}

@end
