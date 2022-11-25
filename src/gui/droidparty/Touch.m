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
		
		self.sendName = [Gui filterEmptyStringValues:line[7]];
		if(![self hasValidSendName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Touch: dropping, send name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			[line[5] floatValue], [line[6] floatValue]);
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
	if(touchDown) {
		CGContextSetLineWidth(context, self.gui.lineWidth * 2.0);
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
	[self sendList:@[
		@(pos.x / CGRectGetWidth(self.frame)),
		@(pos.y / CGRectGetHeight(self.frame))
	]];
	touchDown = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self];
	[self sendList:@[
		@(pos.x / CGRectGetWidth(self.frame)),
		@(pos.y / CGRectGetHeight(self.frame))
	]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self sendList:@[@(-1), @(-1)]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchDown = NO;
	[self sendList:@[@(-1), @(-1)]];
}

@end
