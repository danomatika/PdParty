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

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 18) { // sanity check
		DDLogWarn(@"Toggle: cannot create, atom line length < 18");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.nonZeroValue = 1;
		
		self.sendName = [Gui filterEmptyStringValues:line[7]];
		self.receiveName = [Gui filterEmptyStringValues:line[8]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Toggle: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[5] floatValue], [line[5] floatValue]);
		
		self.inits = [line[6] boolValue];
		
		self.label.text = [Gui filterEmptyStringValues:line[9]];	
		self.originalLabelPos = CGPointMake([line[10] floatValue], [line[11] floatValue]);
		self.labelFontStyle = [line[12] intValue];
		self.labelFontSize = [line[13] floatValue];
		
		self.fillColor = [IEMWidget colorFromAtomColor:line[14]];
		self.controlColor = [IEMWidget colorFromAtomColor:line[15]];
		self.label.textColor = [IEMWidget colorFromAtomColor:line[16]];
		
		self.nonZeroValue = [line[18] floatValue];
		if(self.inits) {
			self.value = [line[17] floatValue];
		}
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, self.gui.lineWidth);
	
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
		CGContextSetLineWidth(context, self.gui.lineWidth * w);
		
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

- (void)reshape {

	// bounds
	self.frame = CGRectMake(
		round((self.originalFrame.origin.x - self.gui.viewport.origin.x) * self.gui.scaleX),
		round((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleWidth),
		round(self.originalFrame.size.height * self.gui.scaleHeight));

	// label
	[self reshapeLabel];
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
			CLAMP([arguments[0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([arguments[0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"nonzero"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// nonzero value
		self.nonZeroValue = [arguments[0] integerValue];
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

@end
