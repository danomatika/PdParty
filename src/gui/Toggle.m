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
#import "Toggle.h"

#import "Gui.h"

@implementation Toggle

+ (id)toggleFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 18) { // sanity check
		DDLogWarn(@"Toggle: Cannot create, atom line length < 18");
		return nil;
	}

	Toggle *t = [[Toggle alloc] initWithFrame:CGRectZero];

	t.sendName = [gui formatAtomString:[line objectAtIndex:7]];
	t.receiveName = [gui formatAtomString:[line objectAtIndex:8]];
	if(![t hasValidSendName] && ![t hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Toggle: Dropping, send/receive names are empty");
		return nil;
	}
	
	t.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue], [[line objectAtIndex:5] floatValue]);
	
	t.inits = [[line objectAtIndex:6] boolValue];
	
	t.label.text = [gui formatAtomString:[line objectAtIndex:9]];	
	t.originalLabelPos = CGPointMake([[line objectAtIndex:10] floatValue], [[line objectAtIndex:11] floatValue]);
	
	t.fillColor = [Gui colorFromIEMColor:[[line objectAtIndex:14] integerValue]];
	t.controlColor = [Gui colorFromIEMColor:[[line objectAtIndex:15] integerValue]];
	t.label.textColor = [Gui colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	
	t.toggleValue = [[line objectAtIndex:18] floatValue];
	t.value = [[line objectAtIndex:17] floatValue];
	
	[t reshapeForGui:gui];
	
	[t sendInitValue];
	
	return t;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if (self) {
		self.toggleValue = 1;
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
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, rect.size.width-1, rect.size.height-1));
	
	// toggle
	CGContextSetStrokeColorWithColor(context, self.controlColor.CGColor);
	if(self.value != 0) {
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, 2, 2);
		CGContextAddLineToPoint(context, rect.size.width-3, rect.size.height-3);
		CGContextStrokePath(context);
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, rect.size.width-3, 2);
		CGContextAddLineToPoint(context, 2, rect.size.height-3);
		CGContextStrokePath(context);
	}
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	[super reshapeForGui:gui];

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.labelFontSize];
	[self.label sizeToFit];
	self.label.frame = CGRectMake(
		round(self.originalLabelPos.x * gui.scaleX),
		round((self.originalLabelPos.y * gui.scaleY) - gui.labelFontSize),
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

- (void)toggle {
	if(self.value == 0) {
		self.value = self.toggleValue;
	}
	else {
		self.value = 0;
	}
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	if(f != 0) { // remember enabled value
		self.toggleValue = f;
	}
	[super setValue:f];
}

- (NSString *)type {
	return @"Toggle";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggle];
	[self sendFloat:self.value];
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self toggle];
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveSetFloat:(float)received {
	self.value = received;
}

@end
