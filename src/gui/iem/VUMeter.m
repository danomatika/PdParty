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
#import "VUMeter.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

#define VU_MAX_SCALE_CHAR_WIDTH	4

#pragma mark VUMeter

@interface VUMeter () {
	BOOL isDefaultFillColor;
	int rmsLed, peakLed; ///< led bar indices
	int ledSize;
}
- (void)checkHeight;
@end

@implementation VUMeter

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 16) { // sanity check
		LogWarn(@"VUMeter: cannot create, atom line length < 16");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		isDefaultFillColor = NO;
		ledSize = 4;
		self.showScale = YES;
		
		// not interactive, so don't accept touch events
		self.userInteractionEnabled = NO;
	
		self.receiveName = [Gui filterEmptyStringValues:line[7]];
		if(![self hasValidReceiveName]) {
			// drop something we can't interact with
			LogVerbose(@"VUMeter: dropping, receive name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[5] floatValue], [line[6] floatValue]);
		
		self.label.text = [Gui filterEmptyStringValues:line[8]];
		self.originalLabelPos = CGPointMake([line[9] floatValue], [line[10] floatValue]);
		self.labelFontStyle = [line[11] intValue];
		self.labelFontSize = [line[12] floatValue];

		self.fillColor = [IEMWidget colorFromAtomColor:line[13]];
		self.label.textColor = [IEMWidget colorFromAtomColor:line[14]];

		self.showScale = [line[15] boolValue];

		[self checkHeight];
		self.gui = gui;
		
		self.value = -100; // default to off which is -100 dB
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.label.font}]; // assumes monospace font
	int yOffset = charSize.height / 2;

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, self.gui.lineWidth);
		
	CGRect meterRect = CGRectMake(
		0, floor((-2 * self.gui.scaleX) + yOffset),
		round((CGRectGetWidth(self.originalFrame)) * self.gui.scaleWidth),
		round((CGRectGetHeight(self.originalFrame) + 4) * self.gui.scaleHeight));
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillRect(context, meterRect);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, meterRect);
	
	// from g_vumeter.c
	int w4 = CGRectGetWidth(self.originalFrame) / 4,
	    quad1 = ceil(w4 * self.gui.scaleWidth);
	int quad3 = floor((CGRectGetWidth(self.originalFrame) - w4) * self.gui.scaleWidth),
	    end = floor((CGRectGetWidth(self.originalFrame) + 2) * self.gui.scaleWidth);
	int k1 = ledSize + 1, k2 = IEM_VU_STEPS + 1, k3 = k1 / 2;
	int yyy, i, k4 = -k3 - 1;
	
	for(i = 1; i <= IEM_VU_STEPS; ++i) {
		yyy = floor(((k4 + k1 * (k2 - i)) * self.gui.scaleHeight) + yOffset);
		
		// led bar
		if(i == peakLed || i <= rmsLed) {
			int ledw = ledSize - 1 + (i < IEM_VU_STEPS ? 2 : 1);
			UIColor *ledColor = [IEMWidget colorFromIntColor:iemgui_vu_col[i]];
			CGContextSetStrokeColorWithColor(context, ledColor.CGColor);
			if(i == peakLed) {
				CGContextSetLineWidth(context, ledw + 1); // peak LED is slightly fatter
				CGContextMoveToPoint(context, 0, yyy);
				CGContextAddLineToPoint(context,
					floor((CGRectGetWidth(self.originalFrame) * self.gui.scaleWidth)),
					yyy);
			}
			else {
				CGContextSetLineWidth(context, ledw);
				CGContextMoveToPoint(context, quad1, yyy);
				CGContextAddLineToPoint(context, quad3, yyy);
			}
			CGContextStrokePath(context);
		}
				 
		// scale
		if(((i + 2) & 3) && self.showScale) {
			yyy = round((k1 * (k2 - i)) * self.gui.scaleHeight);
			NSString *vuString = [NSString stringWithUTF8String:iemgui_vu_scale_str[i]];
			if(vuString.length > 0) {
				CGPoint stringPos = CGPointMake(end, yyy);
				CGContextSetFillColorWithColor(context, self.label.textColor.CGColor);
				[vuString drawAtPoint:stringPos withAttributes:@{NSFontAttributeName:self.label.font}];
			}
		}
	}
	
	// the ">12" on top
	if(self.showScale) {
		int i = IEM_VU_STEPS + 1;
		yyy = k1 * (k2 - i);
		NSString *vuString = [NSString stringWithUTF8String:iemgui_vu_scale_str[i]];
		CGPoint stringPos = CGPointMake(end, yyy);
		CGContextSetFillColorWithColor(context, self.label.textColor.CGColor);
		[vuString drawAtPoint:stringPos withAttributes:@{NSFontAttributeName:self.label.font}];
	}
}

- (void)reshape {
	
	// reshape label first to make sure font has been set
	[self reshapeLabel];
	CGSize charSize = [@"0" sizeWithAttributes:@{NSFontAttributeName:self.label.font}]; // assumes monospaced font
	charSize.width = ceil(charSize.width);
	charSize.height = ceil(charSize.height);

	// bounds from meter size + optional scale width
	if(self.showScale) {
		self.frame = CGRectMake(
			round((self.originalFrame.origin.x - self.gui.viewport.origin.x - 1) * self.gui.scaleX),
			round(((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY) - (charSize.height / 2)),
			round(((CGRectGetWidth(self.originalFrame) + 1) * self.gui.scaleWidth) + ((charSize.width + 1) * VU_MAX_SCALE_CHAR_WIDTH)),
			round(((CGRectGetHeight(self.originalFrame) + 2) * self.gui.scaleHeight) + charSize.height));
	}
	else {
		self.frame = CGRectMake(
			round((self.originalFrame.origin.x - self.gui.viewport.origin.x - 1) * self.gui.scaleX),
			round(((self.originalFrame.origin.y - self.gui.viewport.origin.y) * self.gui.scaleY) - (charSize.height / 2)),
			round(((CGRectGetWidth(self.originalFrame) + 1) * self.gui.scaleWidth) + 1),
			round((CGRectGetHeight(self.originalFrame) + 2) * self.gui.scaleHeight) + charSize.height);
	}

	// shift label down slightly
	CGRect labelFrame = self.label.frame;
	labelFrame.origin.y += round(charSize.height / 4) + 1;
	self.label.frame = labelFrame;
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	int i;
	if(f <= IEM_VU_MINDB) {
		rmsLed = 0;
	}
	else if(f >= IEM_VU_MAXDB) {
		rmsLed = IEM_VU_STEPS;
	}
	else {
		i = (int)(2.0 * (f + IEM_VU_OFFSET));
		rmsLed = iemgui_vu_db2i[i];
	}
	i = (int)((100.0 * f) + 10000.5);
	[super setValue:(0.01 * (i - 10000))];
}

- (void)setPeakValue:(float)peakValue {
	int i;
	if(peakValue <= IEM_VU_MINDB) {
		peakLed = 0;
	}
	else if(peakValue >= IEM_VU_MAXDB) {
		peakLed = IEM_VU_STEPS;
	}
	else {
		i = (int)(2.0 * (peakValue + IEM_VU_OFFSET));
		peakLed = iemgui_vu_db2i[i];
	}
	i = (int)(100.0 * peakValue + 10000.5);
	_peakValue = 0.01 * (i - 10000);
	// doesn't call setNeedsDisplay,
	// rms & peak values come in pairs so only redisplay once when setting rms
}

- (void)setFillColor:(UIColor *)fillColor {
	CGFloat r, g, b, a;
	[fillColor getRed:&r green:&g blue:&b alpha:&a];
	// check for default color value
	if(r == 0.250980  && g == 0.250980 && b == 0.250980 && a == 1.0) {
		[super setFillColor:[UIColor colorWithWhite:0.25 alpha:1.0]];
		isDefaultFillColor = YES;
	}
	else {
		[super setFillColor:fillColor];
		isDefaultFillColor = NO;
	}
}

- (NSString *)type {
	return @"VUMeter";
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	// no sendName
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 1) {
		if([list isNumberAt:0] && [list isNumberAt:1]) {
			self.peakValue = [list[1] floatValue];
			self.value = [list[0] floatValue];
		}
	}
	else {
		[super receiveList:list fromSource:source];
	}
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"color"] && [arguments count] > 1) {
		// background, label-color (pre-0.47) *or*
		// background, _, label-color (control color ignored by cnv)
		int label = ([arguments count] > 2 ? 2 : 1);
		self.fillColor = [IEMWidget colorFromEditColor:arguments[0]];
		self.label.textColor = [IEMWidget colorFromEditColor:arguments[label]];
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// width, height
		float w = MAX([arguments[0] floatValue], IEM_GUI_MINSIZE);
		float h = CGRectGetHeight(self.originalFrame);
		if([arguments count] > 1 && [arguments isNumberAt:1]) {
			h = [arguments[1] floatValue];
		}
		self.originalFrame = CGRectMake(self.originalFrame.origin.x, self.originalFrame.origin.y, w, h);
		[self checkHeight];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"scale"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		self.showScale = [arguments[0] boolValue];
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"send"] || [message isEqualToString:@"init"]) {
		// has no send & dosen't init
		return NO;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

#pragma mark Private

// from g_vumeter.c
- (void)checkHeight {
	int n = CGRectGetHeight(self.originalFrame) / IEM_VU_STEPS;
	if(n < IEM_VU_MINSIZE) {
		n = IEM_VU_MINSIZE;
	}
	ledSize = n-1;
	CGRect frame = self.originalFrame;
	frame.size.height = IEM_VU_STEPS * n;
	self.originalFrame = frame;
}

@end
