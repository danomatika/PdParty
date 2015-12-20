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
#import "Display.h"

#import "Gui.h"

@implementation Display

+ (id)displayFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 7) { // sanity check
		DDLogWarn(@"Display: cannot create, atom line length < 7");
		return nil;
	}

	Display *d = [[Display alloc] initWithFrame:CGRectZero];

	d.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	if(![d hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Display: dropping, receive name is empty");
		return nil;
	}
	
	d.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	
	d.gui = gui;
	
	return d;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.label.adjustsFontSizeToFitWidth = YES;
		self.label.numberOfLines = 0;
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
	CGContextSetLineWidth(context, 1.0);
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
	self.label.preferredMaxLayoutWidth = round(CGRectGetWidth(self.frame) * 0.75);
	self.label.frame = CGRectMake(
		round(CGRectGetWidth(self.frame) * 0.125), round(CGRectGetHeight(self.frame) * 0.125),
		round(CGRectGetWidth(self.frame) * 0.75), round(CGRectGetHeight(self.frame) * 0.75));
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Display";
}

#pragma mark WidgetListener

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.label.text = [[NSNumber numberWithFloat:received] stringValue];
	[self reshapeForGui:self.gui];
	[self setNeedsDisplay];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	self.label.text = symbol;
	[self reshapeForGui:self.gui];
	[self setNeedsDisplay];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	NSMutableString *text = [[NSMutableString alloc] init];
	for(int i = 0; i < [list count]; ++i) {
		
		if(i > 0) {
			[text appendString:@" "];
		}
		
		if([list isStringAt:i]) {
			[text appendString:[list objectAtIndex:i]];
		}
		else if([list isNumberAt:i]) {
			[text appendString:[[list objectAtIndex:i] stringValue]];
		}
	}
	self.label.text = text;
	[self reshapeForGui:self.gui];
	[self setNeedsDisplay];
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	// assume all messages are a list to display as a string
	NSMutableString *text = [NSMutableString stringWithString:message];
	for(int i = 0; i < [arguments count]; ++i) {
		[text appendString:@" "];
		if([arguments isStringAt:i]) {
			[text appendString:[arguments objectAtIndex:i]];
		}
		else if([arguments isNumberAt:i]) {
			[text appendString:[[arguments objectAtIndex:i] stringValue]];
		}
	}
	self.label.text = text;
	[self reshapeForGui:self.gui];
	[self setNeedsDisplay];
	return YES;
}

@end
