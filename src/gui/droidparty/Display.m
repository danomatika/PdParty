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

	Display *d = [[self alloc] initWithFrame:CGRectZero];

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
		if([Util deviceOSVersion] < 7.0) {
			self.label.lineBreakMode = NSLineBreakByWordWrapping;
		}
		else {
			self.label.numberOfLines = 0;
		}
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
	self.label.font = [UIFont fontWithName:gui.fontName size:(int)round(CGRectGetHeight(self.frame) * 0.75)];
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

- (void)receiveBangFromSource:(NSString *)source {
	// swallows bangs
}

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
	self.label.text = [list componentsJoinedByString:@" "];
	[self reshapeForGui:self.gui];
	[self setNeedsDisplay];
}

- (void)receiveSetFloat:(float)received {
	[self receiveFloat:received fromSource:self.receiveName];
}

- (void)receiveSetSymbol:(NSString *)symbol {
	[self receiveSymbol:symbol fromSource:self.receiveName];
}

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	// assume all messages are a list to display as a string
	if([message isEqualToString:@"set"]) {
		[self receiveList:arguments fromSource:self.receiveName];
	}
	else {
		NSArray *list = [[NSArray arrayWithObject:message] arrayByAddingObjectsFromArray:arguments];
		[self receiveList:list fromSource:self.receiveName];
	}
	return YES;
}

@end
