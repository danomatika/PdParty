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
#import "Numberbox.h"

#import "Gui.h"

@interface Numberbox () {
	BOOL touchDown;
}
@end

@implementation Numberbox

+ (id)numberboxFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 10) { // sanity check
		DDLogWarn(@"Numberbox: cannot create, atom line length < 10");
		return nil;
	}

	Numberbox *n = [[Numberbox alloc] initWithFrame:CGRectZero];
	
	n.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	n.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	if(![n hasValidSendName] && ![n hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Numberbox: dropping, send/receive names are empty");
		return nil;
	}
	
	n.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);

	n.valueWidth = 3; // fixed width
	n.minValue = [[line objectAtIndex:9] floatValue];
	n.maxValue = [[line objectAtIndex:10] floatValue];
	n.inits = YES;
	
	if ([line count] > 10) {
		n.value = [[line objectAtIndex:11] floatValue];
	}
	else {
		n.value = 0; // set text in number label
	}
	
	return n;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.valueLabel.textAlignment = NSTextAlignmentCenter;
		
		// don't need the label
		[self.label removeFromSuperview];
		self.label = nil;
		
		touchDown = NO;
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
	if(touchDown) {
		CGContextSetLineWidth(context, 2.0);
	}
	else {
		CGContextSetLineWidth(context, 1.0);
	}
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds (from Widget)
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		round(self.originalFrame.size.width * gui.scaleX),
		round(self.originalFrame.size.height * gui.scaleX));
	
	// value label
	[self reshapeValueLabel];
}

- (void)reshapeValueLabel {
	self.valueLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	CGSize charSize = [@"0" sizeWithFont:self.valueLabel.font]; // assumes monspaced font
	self.valueLabel.preferredMaxLayoutWidth = charSize.width * self.valueWidth;
	[self.valueLabel sizeToFit];
	self.valueLabel.center = CGPointMake(round(CGRectGetWidth(self.frame)/2), round(CGRectGetHeight(self.frame)/2));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	[super setValue:value];
	[self reshapeValueLabel];
}

- (NSString *)type {
	return @"Numberbox";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	touchDown = YES;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	touchDown = NO;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	touchDown = NO;
	[self setNeedsDisplay];
}

#pragma mark WidgetListener

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

- (void)receiveSetSymbol:(NSString *)symbol {
	// swallows set symbols
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	// swallow range message sent by droidparty numberbox.pd abstraction
	if([message isEqualToString:@"range"]) {
		return YES;
	}
	return NO;
}

@end
