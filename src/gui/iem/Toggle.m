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
#import "Toggle.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@implementation Toggle

+ (id)toggleFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Toggle: cannot create, atom line length < 18");
		return nil;
	}

	Toggle *t = [[Toggle alloc] initWithFrame:CGRectZero];

	t.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	t.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	if(![t hasValidSendName] && ![t hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Toggle: dropping, send/receive names are empty");
		return nil;
	}
	
	t.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:5] floatValue]);
	
	t.inits = [[line objectAtIndex:6] boolValue];
	
	t.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:9]];	
	t.originalLabelPos = CGPointMake([[line objectAtIndex:10] floatValue], [[line objectAtIndex:11] floatValue]);
	t.labelFontStyle = [[line objectAtIndex:12] intValue];
	t.labelFontSize = [[line objectAtIndex:13] floatValue];
	
	t.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:14] intValue]];
	t.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	t.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	
	t.gui = gui;
	
	t.nonZeroValue = [[line objectAtIndex:18] floatValue];
	if(t.inits) {
		t.value = [[line objectAtIndex:17] floatValue];
	}
	
	return t;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.nonZeroValue = 1;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetLineWidth(context, 1.0);
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillRect(context, rect);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
	
	// toggle
	if(self.value != 0) {
		
		// stroke width increases with size
		CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
		int w = 1;
		if(CGRectGetWidth(self.originalFrame) >= 60) {
			w = 3;
		}
		else if(CGRectGetWidth(self.originalFrame) >= 30) {
			w = 2;
		}
		CGContextSetLineWidth(context, w);
		
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, w, w);
		CGContextAddLineToPoint(context, rect.size.width-w-1, rect.size.height-w-1);
		CGContextStrokePath(context);
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, rect.size.width-w-1, w);
		CGContextAddLineToPoint(context, w, rect.size.height-w-1);
		CGContextStrokePath(context);
	}
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		round(self.originalFrame.size.width * gui.scaleX),
		round(self.originalFrame.size.height * gui.scaleX));

	// label
	[self reshapeLabelForGui:gui];
}

- (void)toggle {
	if(self.value == 0) {
		self.value = self.nonZeroValue;
	}
	else {
		self.value = 0;
	}
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	if(f != 0) {
		f = self.nonZeroValue;
	}
	[super setValue:f];
}

- (void)setNonZeroValue:(float)nonZeroValue {
	if(nonZeroValue != 0.0) {
		_nonZeroValue = nonZeroValue;
	}
}

- (NSString *)type {
	return @"Toggle";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggle];
	[self sendFloat:self.value];
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self toggle];
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:received]; // Pd 0.46+ doesn't clip incoming values
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {

	if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// size
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		[self reshapeForGui:self.gui];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"nonzero"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// nonzero value
		self.nonZeroValue = [[arguments objectAtIndex:0] integerValue];
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

@end
