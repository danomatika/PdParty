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
#import "Number2.h"

#import "Gui.h"

@interface Number2 () {
	double convFactor; // scaling factor for lin/log value conversion
	int cornerSize; // bent corner pixel size
	int touchPrevY;
	bool isOneFinger;
	BOOL isControlColorBlack;
	BOOL isValueLabelRed;
}
- (void)checkMinAndMax;
@end

@implementation Number2

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 23) { // sanity check
		DDLogWarn(@"Numberbox2: cannot create, atom line length < 23");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		touchPrevY = 0;
		isOneFinger = YES;
		isControlColorBlack = NO;
		isValueLabelRed = NO;
		
		self.multipleTouchEnabled = YES;
		
		self.log = 0;
		self.logHeight = 256;
		
		self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.valueLabel.textAlignment = NSTextAlignmentLeft;
		self.valueLabel.lineBreakMode = NSLineBreakByClipping;
		self.valueLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.valueLabel];

		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
		self.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Numberbox2: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			0, [[line objectAtIndex:6] floatValue]); // width based on valueWidth

		self.valueWidth = [[line objectAtIndex:5] integerValue];
		self.minValue = [[line objectAtIndex:7] floatValue];
		self.maxValue = [[line objectAtIndex:8] floatValue];
		self.log = [[line objectAtIndex:9] boolValue];
		self.inits = [[line objectAtIndex:10] boolValue];
		
		self.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
		self.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue], [[line objectAtIndex:15] floatValue]);
		self.labelFontStyle = [[line objectAtIndex:16] intValue];
		self.labelFontSize = [[line objectAtIndex:17] floatValue];
		
		self.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] integerValue]];
		self.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] integerValue]];
		self.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] integerValue]];
		
		if(self.inits) {
			self.value = [[line objectAtIndex:21] floatValue];
		}
		else {
			self.value = 0; // set label
		}
		if([line count] > 22 && [line isNumberAt:22]) {
			self.logHeight = [[line objectAtIndex:22] floatValue];
		}
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);
	
	// bounds as path
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-cornerSize, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, cornerSize);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, 0);
	
	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	
	// triangle
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 1, 1);
	CGContextAddLineToPoint(context, rect.size.height/2, rect.size.height/2);
	CGContextAddLineToPoint(context, 1, rect.size.height-1);
	CGContextStrokePath(context);
	
	CGPathRelease(path);
}

- (void)reshape {
	
	// value label
	self.valueLabel.font = [UIFont fontWithName:self.gui.fontName size:self.labelFontSize * self.gui.scaleX];
	CGSize charSize = [@"0" sizeWithFont:self.valueLabel.font]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth =
		(charSize.width * self.valueWidth) +
		((CGRectGetHeight(self.originalFrame) / 2) + 4) * self.gui.scaleX;
	[self.valueLabel sizeToFit];
	CGRect valueLabelFrame = self.valueLabel.frame;
	if(valueLabelFrame.size.width < self.valueLabel.preferredMaxLayoutWidth) {
		// make sure width matches valueWidth
		valueLabelFrame.size.width = self.valueLabel.preferredMaxLayoutWidth;
	}
	valueLabelFrame.origin = CGPointMake(
		round((CGRectGetHeight(self.originalFrame) * 0.5 + 1) * self.gui.scaleX),
		round(((CGRectGetHeight(self.originalFrame) * 0.5 + 0.5) * self.gui.scaleX) -
			  CGRectGetHeight(self.valueLabel.frame) * 0.5));
	self.valueLabel.frame = valueLabelFrame;
	
	// width from value label
	CGRect frame = CGRectMake(
		round(self.originalFrame.origin.x * self.gui.scaleX),
		round(self.originalFrame.origin.y * self.gui.scaleY),
		round(CGRectGetWidth(self.valueLabel.frame) + self.valueLabel.frame.origin.x + (4 * self.gui.scaleX)),
		round(CGRectGetHeight(self.originalFrame) * self.gui.scaleX));
	self.frame = frame;
	cornerSize = 4 * self.gui.scaleX;

	// label
	[self reshapeLabel];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = CLAMP(value, self.minValue, self.maxValue);
	}
	self.valueLabel.text = [Widget stringFromFloat:value withWidth:self.valueWidth];
	
	// set red interaction color?
	if(touchPrevY > 0) { // assume first interaction is not at 0 (where fat fingers can't go)
		self.valueLabel.textColor = [UIColor redColor];
		isValueLabelRed = YES;
	}
	[super setValue:value];
}

- (void)setValueWidth:(int)valueWidth {
	_valueWidth = MAX(valueWidth, 1);
}

- (void)setControlColor:(UIColor *)controlColor {
	[super setControlColor:controlColor];
	self.valueLabel.textColor = self.controlColor;
	isValueLabelRed = NO;
}

- (void)setLog:(BOOL)log {
	_log = log;
	if(_log) {
		[self checkMinAndMax];
	}
}

// from g_numbox.c
- (void)setLogHeight:(float)logHeight {
	if(logHeight < 10.0) {
		logHeight = 10.0;
	}
	_logHeight = logHeight;
	if(self.log) {
		convFactor = exp(log(self.maxValue / self.minValue) / (double)(_logHeight));
	}
	else {
		convFactor = 1.0;
	}
}

- (NSString *)type {
	return @"Number2";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	touchPrevY = pos.y;
	if(touches.count > 1) {
		isOneFinger = NO;
	}
	else {
		isOneFinger = YES;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	int diff = touchPrevY - pos.y;
	if(diff != 0) {
		double k2 = 1.0;
		double v = self.value;
		if(!isOneFinger) {
			k2 = 0.01;
		}
		if(self.log) {
			v *= pow(convFactor, -k2 * diff);
		}
		else {
			v += k2 * diff;
		}
		self.value = v;
		[self sendFloat:self.value];
	}
	touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
	isOneFinger = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
	isOneFinger = YES;
}

// reset red label color if any *other* UIView was hit
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *view = [super hitTest:point withEvent:event];
	if(view != self && isValueLabelRed) {
		self.valueLabel.textColor = self.controlColor;
		isValueLabelRed = NO;
		[self setNeedsDisplay];
	}
	return view;
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	// swallows symbols
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (void)receiveSetSymbol:(NSString *)symbol {
	// swallows set symbols
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if([message isEqualToString:@"size"] && [arguments count] > 0 && [arguments isNumberAt:0]) {
		// value width in chars, height
		self.valueWidth = [[arguments objectAtIndex:0] integerValue];
		if([arguments count] > 1 && [arguments isNumberAt:1]) {
		self.originalFrame = CGRectMake(
			self.originalFrame.origin.x, self.originalFrame.origin.y,
			CGRectGetWidth(self.originalFrame),
			MAX([[arguments objectAtIndex:1] floatValue], 8));
		}
		[self reshape];
		[self setNeedsDisplay];
		return YES;
	}
	else if([message isEqualToString:@"range"] && [arguments count] > 1 &&
		([arguments isNumberAt:0] && [arguments isNumberAt:1])) {
		// low, high
		self.minValue = [[arguments objectAtIndex:0] floatValue];
		self.maxValue = [[arguments objectAtIndex:1] floatValue];
		[self checkMinAndMax];
		return YES;
	}
	else if([message isEqualToString:@"lin"]) {
		self.log = NO;
		return YES;
	}
	else if([message isEqualToString:@"log"]) {
		self.log = YES;
		return YES;
	}
	else {
		return [super receiveEditMessage:message withArguments:arguments];
	}
	return NO;
}

#pragma mark Private

// from g_numbox.c
- (void)checkMinAndMax {
	if(self.log) {
		if((self.minValue == 0.0) && (self.maxValue == 0.0)) {
			self.maxValue = 1.0;
		}
		if(self.maxValue > 0.0) {
			if(self.minValue <= 0.0) {
				self.minValue = 0.01 * self.maxValue;
			}
		}
		else {
			if(self.minValue > 0.0) {
				self.maxValue = 0.01 * self.minValue;
			}
		}
	}
	if(self.value < self.minValue) {
		[self setValue:self.minValue];
	}
	if(self.value > self.maxValue) {
		[self setValue:self.maxValue];
	}
	if(self.log) {
		convFactor = exp(log(self.maxValue / self.minValue) / (double)(self.logHeight));
	}
	else {
		convFactor = 1.0;
	}
}

@end
