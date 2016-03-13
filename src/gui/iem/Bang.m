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
#import "Bang.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

@interface Bang () {
	double timestamp;
	double elapsedHoldTimeMS; // how many ms have elapsed before an interrupt
	NSTimer *flashTimer;
}
- (void)checkFlashTimes;
- (void)stopFlash:(NSTimer *)timer;
- (void)resumeFlash:(NSTimer *)timer;
@end

@implementation Bang

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 18) { // sanity check
		DDLogWarn(@"Bang: cannot create, atom line length < 18");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		_interruptTimeMS = IEM_BNG_DEFAULTBREAKFLASHTIME;
		_holdTimeMS = IEM_BNG_DEFAULTHOLDFLASHTIME;
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:9]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:10]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Bang: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:5] floatValue]);
		
		self.holdTimeMS = [[line objectAtIndex:6] intValue];
		self.interruptTimeMS = [[line objectAtIndex:7] intValue];
		self.inits = [[line objectAtIndex:8] boolValue];
		[self checkFlashTimes];
		
		self.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
		self.originalLabelPos = CGPointMake([[line objectAtIndex:12] floatValue], [[line objectAtIndex:13] floatValue]);
		self.labelFontStyle = [[line objectAtIndex:14] intValue];
		self.labelFontSize = [[line objectAtIndex:15] floatValue];
		
		self.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:16] intValue]];
		self.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:17] intValue]];
		self.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] intValue]];
	}
	return self;
}

- (void)dealloc {
	// clear timer in case it's active
	[flashTimer invalidate];
	flashTimer = nil;
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

	// bang
	CGRect circleFrame = CGRectMake(1, 1, rect.size.width-3, rect.size.height-3);
	if(self.value != 0) {
		CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
		CGContextFillEllipseInRect(context, circleFrame);
	}
	CGContextStrokeEllipseInRect(context, circleFrame);
}

- (void)reshape {

	// bounds
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * self.gui.scaleX),
		round(self.originalFrame.origin.y * self.gui.scaleY),
		round(self.originalFrame.size.width * self.gui.scaleX),
		round(self.originalFrame.size.height * self.gui.scaleX));

	// label
	[self reshapeLabel];
}

- (void)sendInitValue {
	if(self.inits) {
		[self bang];
	}
}

- (void)bang {

	// start new flash
	if(!flashTimer) {
		// start flash with full hold time
		timestamp = CACurrentMediaTime();
		flashTimer = [NSTimer scheduledTimerWithTimeInterval:((float)self.holdTimeMS/1000.f)
													  target:self
													selector:@selector(stopFlash:)
													userInfo:nil
													 repeats:NO];
		self.value = 1;
		elapsedHoldTimeMS = 0;
	}
	else { // interrupted
		[flashTimer invalidate];
		flashTimer = NULL;
		
		elapsedHoldTimeMS = (CACurrentMediaTime() - timestamp) * 1000;
		
		// retrigger flash after interrupt time
		flashTimer = [NSTimer scheduledTimerWithTimeInterval:((float)self.interruptTimeMS/1000.f)
													  target:self
													selector:@selector(resumeFlash:)
													userInfo:nil
													 repeats:NO];
		self.value = 0;
	}
}

#pragma mark Overridden Getters / Setters

- (void)setInterruptTimeMS:(int)interruptTimeMS {
	_interruptTimeMS = MAX(interruptTimeMS, IEM_BNG_MINBREAKFLASHTIME);
}

- (void)setHoldTimeMS:(int)holdTimeMS {
	_holdTimeMS = MAX(holdTimeMS, IEM_BNG_MINHOLDFLASHTIME);
}

- (NSString *)type {
	return @"Bang";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self receiveBangFromSource:@""];
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self bang];
	[self sendBang];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	[self receiveBangFromSource:@""];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	[self receiveBangFromSource:@""];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	[self receiveBangFromSource:@""];
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// size
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE),
			CLAMP([[arguments objectAtIndex:0] floatValue], IEM_GUI_MINSIZE, IEM_GUI_MAXSIZE));
		[self reshape];
		[self setNeedsDisplay];
	}
	else if([message isEqualToString:@"flashtime"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// interrupt time, hold time
		self.interruptTimeMS = [[arguments objectAtIndex:0] floatValue];
		self.holdTimeMS = [[arguments objectAtIndex:1] floatValue];
		[self checkFlashTimes];
	}
	else {
		if(![super receiveEditMessage:message withArguments:arguments]) {
			// treat anything else as a bang
			[self receiveBangFromSource:@""];
		}
	}
	return YES;
}

#pragma Private

// form g_bang.c
- (void)checkFlashTimes {
	if(self.interruptTimeMS > self.holdTimeMS) {
		float h;
		h = self.holdTimeMS;
		self.holdTimeMS = self.interruptTimeMS;
		self.interruptTimeMS = h;
	}
}

- (void)stopFlash:(NSTimer *)timer {
	self.value = 0;
	elapsedHoldTimeMS = 0;
	[flashTimer invalidate];
	flashTimer = NULL;
}

- (void)resumeFlash:(NSTimer *)timer {
	[flashTimer invalidate];
	
	// restart timer to finish
	double resumeHoldTime = self.holdTimeMS - (elapsedHoldTimeMS);
	if(resumeHoldTime > 0) {
		flashTimer = [NSTimer scheduledTimerWithTimeInterval:(resumeHoldTime/1000.f)
												  target:self
												selector:@selector(stopFlash:)
												userInfo:nil
												 repeats:NO];
		self.value = 1;
	}
	else { // stop if there is no time left to show
		[self stopFlash:nil];
	}
}

@end
