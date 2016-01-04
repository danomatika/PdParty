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
#import "Taplist.h"

#import "Gui.h"

@interface Taplist () {
	BOOL touchDown;
}
- (void)sendValues;
@end

@implementation Taplist

+ (id)taplistFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 9) { // sanity check
		DDLogWarn(@"Taplist: cannot create, atom line length < 9");
		return nil;
	}

	Taplist *t = [[Taplist alloc] initWithFrame:CGRectZero];
	
	t.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	t.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	if(![t hasValidSendName] && ![t hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Taplist: dropping, send/receive names are empty");
		return nil;
	}
	
	t.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	
	for(int i = 9; i < [line count]; ++i) {
		[t.list addObject:[line objectAtIndex:i]];
	}
	t.value = 0;
	
	return t;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.list = [[NSMutableArray alloc] init];
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.label.adjustsFontSizeToFitWidth = YES;
		self.label.numberOfLines = 0;
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

	// bounds
	[super reshapeForGui:gui];

	// label
	[self reshapeLabel];
}

- (void)reshapeLabel {
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	self.label.preferredMaxLayoutWidth = round(CGRectGetWidth(self.frame) * 0.75);
	self.label.frame = CGRectMake(
		round(CGRectGetWidth(self.frame) * 0.125), round(CGRectGetHeight(self.frame) * 0.125),
		round(CGRectGetWidth(self.frame) * 0.75), round(CGRectGetHeight(self.frame) * 0.75));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.list) {
		[super setValue:value];
		if(self.value < [self.list count]) {
			self.label.text = [self.list objectAtIndex:(int)value];
			[self reshapeLabel];
		}
	}
}

- (NSString *)type {
	return @"Taplist";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = YES;
	self.value = (int)(self.value + 1) % [self.list count]; // go to the next item in our list
	[self sendValues];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self setNeedsDisplay];
}

#pragma mark WidgetListener

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = (int)received % [self.list count];
	[self sendValues];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	// swallow symbols
}

#pragma mark Private

- (void)sendValues {
	if(self.value < [self.list count]) {
		[self sendSymbol:[self.list objectAtIndex:(int)self.value]];
	}
	[PdBase sendFloat:self.value toReceiver:[self.sendName stringByAppendingString:@"/idx"]];
}

@end
