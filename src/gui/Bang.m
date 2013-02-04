/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#import "Bang.h"

#import "Gui.h"

@interface Bang () {
	NSTimer *flashTimer;
}
- (void)stopFlash:(NSTimer*)timer;
@end

@implementation Bang

+ (id)bangFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Cannot create Bang, atom line length < 18");
		return nil;
	}

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX),
		round([[line objectAtIndex:5] floatValue] * gui.scaleX));

	Bang *b = [[Bang alloc] initWithFrame:frame];

	b.sendName = [gui formatAtomString:[line objectAtIndex:9]];
	b.receiveName = [gui formatAtomString:[line objectAtIndex:10]];
	if(![b hasValidSendName] && ![b hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Dropping Bang, send/receive names are empty");
		return nil;
	}
	
	b.label.text = [gui formatAtomString:[line objectAtIndex:11]];
	if(![b.label.text isEqualToString:@""]) {
		b.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
		[b.label sizeToFit];
		CGRect labelFrame = CGRectMake(
			round([[line objectAtIndex:12] floatValue] * gui.scaleX),
			round(([[line objectAtIndex:13] floatValue] * gui.scaleY) - gui.fontSize),
			b.label.frame.size.width,
			b.label.frame.size.height
		);
		b.label.frame = labelFrame;
		[b addSubview:b.label];
	}
	
	b.bangTimeMS = [[line objectAtIndex:6] integerValue];
	
	return b;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextSetLineWidth(context, 1.0);
	
    CGRect frame = rect;
	
	// border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, frame.size.width-1, 0);
    CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, 0);
    CGContextStrokePath(context);

	// bang
	CGRect circleFrame = CGRectMake(1, 1, frame.size.width-3, frame.size.height-3);
	if(self.value != 0) {
		CGContextFillEllipseInRect(context, circleFrame);
	}
	CGContextStrokeEllipseInRect(context, circleFrame);
}

- (void)bang {
	if(flashTimer) {
		[flashTimer invalidate];
		flashTimer = NULL;
	}
	flashTimer = [NSTimer scheduledTimerWithTimeInterval:((float)self.bangTimeMS/1000.f)
												  target:self
												selector:@selector(stopFlash:)
												userInfo:nil
												 repeats:NO];
	self.value = 1;
}

#pragma mark Overridden Getters & Setters

- (NSString*)type {
	return @"Bang";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self bang];
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	[self bang];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	[self bang];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	[self bang];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	[self bang];
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	[self bang];
}

#pragma Private

- (void)stopFlash:(NSTimer*)timer {
  self.value = 0;
}

@end
