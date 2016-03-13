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
#import "Touch.h"

#import "Gui.h"

@interface Touch () {
	BOOL touchDown;
}
@end

@implementation Touch

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 7) { // sanity check
		DDLogWarn(@"Touch: cannot create, atom line length < 7");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.label = nil; // don't need label
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
		if(![self hasValidSendName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Touch: dropping, send name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
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

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Touch";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:(pos.x / CGRectGetWidth(self.frame))],
		[NSNumber numberWithFloat:(pos.y / CGRectGetHeight(self.frame))], nil]];
	touchDown = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:(pos.x / CGRectGetWidth(self.frame))],
		[NSNumber numberWithFloat:(pos.y / CGRectGetHeight(self.frame))], nil]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:-1],
		[NSNumber numberWithFloat:-1], nil]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:-1],
		[NSNumber numberWithFloat:-1], nil]];
}

@end
