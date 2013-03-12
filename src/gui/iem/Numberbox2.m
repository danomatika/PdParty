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
#import "Numberbox2.h"

#import "Gui.h"

@interface Numberbox2 () {
	int cornerSize; // bent corner pixel size
	int touchPrevY;
	BOOL isControlColorBlack;
	BOOL isValueLabelRed;
}

@end

@implementation Numberbox2

+ (id)numberbox2FromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 11) { // sanity check
		DDLogWarn(@"Numberbox2: Cannot create, atom line length < 11");
		return nil;
	}

	Numberbox2 *n = [[Numberbox2 alloc] initWithFrame:CGRectZero];

	n.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:11]];
	n.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:12]];
	if(![n hasValidSendName] && ![n hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Numberbox2: Dropping, send/receive names are empty");
		return nil;
	}
	
	n.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, [[line objectAtIndex:6] floatValue]); // width based on valueWidth

	n.valueWidth = [[line objectAtIndex:5] integerValue];
	n.minValue = [[line objectAtIndex:7] floatValue];
	n.maxValue = [[line objectAtIndex:8] floatValue];
	n.log = [[line objectAtIndex:9] integerValue];
	n.inits = [[line objectAtIndex:10] boolValue];
	
	n.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:13]];
	n.originalLabelPos = CGPointMake([[line objectAtIndex:14] floatValue], [[line objectAtIndex:15] floatValue]);
	n.labelFontSize = [[line objectAtIndex:17] floatValue];
	
	n.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:18] integerValue]];
	n.controlColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:19] integerValue]];
	n.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:20] integerValue]];
	
	n.value = [[line objectAtIndex:21] floatValue];
	n.logHeight = [[line objectAtIndex:22] floatValue];

	[n reshapeForGui:gui];

	return n;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		
		self.log = 0;
		self.logHeight = 256;
		
		self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.valueLabel.textAlignment = NSTextAlignmentLeft;
		self.valueLabel.lineBreakMode = NSLineBreakByClipping;
		self.valueLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.valueLabel];
		
		self.valueLabelFormatter = [[NSNumberFormatter alloc] init];
		//self.valueLabelFormatter.numberStyle = NSNumberFormatterScientificStyle;
		self.valueLabelFormatter.maximumSignificantDigits = 6;
		self.valueLabelFormatter.paddingCharacter = @" ";
		self.valueLabelFormatter.paddingPosition = NSNumberFormatterPadAfterSuffix;
		
		touchPrevY = 0;
		isControlColorBlack = NO;
		isValueLabelRed = NO;
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
}

- (void)reshapeForGui:(Gui *)gui {
	
	// value label
	self.valueLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:self.labelFontSize * gui.scaleX];
	CGSize charSize = [@"0" sizeWithFont:self.valueLabel.font]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth = charSize.width * self.valueWidth;
	[self.valueLabel sizeToFit];
	CGRect valueLabelFrame = self.valueLabel.frame;
	if(valueLabelFrame.size.width < self.valueLabel.preferredMaxLayoutWidth) {
		// make sure width matches valueWidth
		valueLabelFrame.size.width = self.valueLabel.preferredMaxLayoutWidth;
	}
	valueLabelFrame.origin = CGPointMake(round(gui.scaleX + (valueLabelFrame.size.height * 0.5)), round(2.0 * gui.scaleX));
	self.valueLabel.frame = valueLabelFrame;
	
	// bounds from value label size
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		round(CGRectGetWidth(self.valueLabel.frame) +
			 (CGRectGetHeight(self.valueLabel.frame) * 0.5) +
			 (charSize.width * 3) + (2 * gui.scaleX)), // space out right edge
		round(CGRectGetHeight(self.valueLabel.frame) + (2 * gui.scaleX)));
	cornerSize = CGRectGetHeight(self.valueLabel.frame) * 0.40;

	// label
	[self reshapeLabelForGui:gui];
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = MIN(self.maxValue, MAX(value, self.minValue));
	}
	
	// set sig fig formatting to make sure 0 values are returned as "0" instead of "0.0"
	// http://stackoverflow.com/questions/13897372/nsnumberformatter-with-significant-digits-formats-0-0-incorrectly/15281611
	if(fabs(value) < 1e-6) {
		self.valueLabelFormatter.usesSignificantDigits = NO;
	}
	else {
		self.valueLabelFormatter.usesSignificantDigits = YES;
	}
	self.valueLabel.text = [self.valueLabelFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
	if(isControlColorBlack) { // set red interaction color?
		if(touchPrevY > 0) { // assume first interaction is not at 0 (where fat fingers can't go)
			self.valueLabel.textColor = [UIColor redColor];
			isValueLabelRed = YES;
		}
	}
	else {
		self.valueLabel.textColor = self.controlColor;
	}
	[super setValue:value];
}

- (void)setValueWidth:(int)valueWidth {
	[self.valueLabelFormatter setFormatWidth:valueWidth];
	_valueWidth = valueWidth;
}

- (void)setControlColor:(UIColor *)controlColor {
	CGFloat r, g, b, a;
	[controlColor getRed:&r green:&g blue:&b alpha:&a];
	if(r == 0.0  && g == 0.0 && b == 0.0 && a == 1.0) {
		isControlColorBlack = YES;
	}
	else {
		isControlColorBlack = NO;
	}
	[super setControlColor:controlColor];
}

- (NSString *)type {
	return @"Numberbox2";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	touchPrevY = pos.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	int diff = touchPrevY - pos.y;
	if(diff != 0) {
		self.value = self.value + diff;
		[self sendFloat:self.value];
	}
	touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
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

#pragma mark PdListener

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

@end
