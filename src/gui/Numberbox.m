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

@interface Numberbox () {}
@property (nonatomic, assign) int touchPrevY;
@end

@implementation Numberbox

+ (id)numberboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	if(line.count < 11) { // sanity check
		DDLogWarn(@"Numberbox: Cannot create, atom line length < 11");
		return nil;
	}

	Numberbox *n = [[Numberbox alloc] initWithFrame:CGRectZero];

	n.sendName = [gui formatAtomString:[line objectAtIndex:10]];
	n.receiveName = [gui formatAtomString:[line objectAtIndex:9]];
	if(![n hasValidSendName] && ![n hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Numberbox: Dropping, send/receive names are empty");
		return nil;
	}
	
	n.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on numwidth

	n.numWidth = [[line objectAtIndex:4] integerValue];
	n.minValue = [[line objectAtIndex:5] floatValue];
	n.maxValue = [[line objectAtIndex:6] floatValue];
	n.value = 0; // set text in number label
		
	n.labelPos = [[line objectAtIndex:7] integerValue];
	n.label.text = [gui formatAtomString:[line objectAtIndex:8]];

	[n reshapeForGui:gui];

	return n;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		
		self.numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.numberLabel setTextAlignment:NSTextAlignmentLeft];
		self.numberLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.numberLabel];
		
		self.numberLabelFormatter = [[NSNumberFormatter alloc] init];
		//self.numberLabelFormatter.numberStyle = NSNumberFormatterScientificStyle;
		self.numberLabelFormatter.maximumSignificantDigits = 6;
		self.numberLabelFormatter.paddingCharacter = @" ";
		self.numberLabelFormatter.paddingPosition = NSNumberFormatterPadAfterSuffix;
		
		self.touchPrevY = 0;
    }
    return self;
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
	CGContextAddLineToPoint(context, frame.size.width-8, 0);
    CGContextAddLineToPoint(context, frame.size.width-1, 8);
	CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, frame.size.height-1);
	CGContextAddLineToPoint(context, 0, 0);
    CGContextStrokePath(context);
}

- (void)reshapeForGui:(Gui *)gui {
	
	// bounds
	self.frame = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		round(((self.numWidth-2) * gui.fontSize) + 3),
		round(gui.fontSize + 8));
		
	// number label
	self.numberLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	self.numberLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.frame);
	self.numberLabel.frame = CGRectMake(2, 1, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));

	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	[self.label sizeToFit];
		
	// set the label pos from the LRUD setting
	int labelPosX, labelPosY;
	switch(self.labelPos) {
		default: // 0 LEFT
			labelPosX = -gui.fontSize*(self.label.text.length-2);
			labelPosY = 0;
			break;
		case 1: // RIGHT
			labelPosX = self.frame.size.width+1;
			labelPosY = 0;
			break;
		case 2: // TOP
			labelPosX = -1;
			labelPosY = -gui.fontSize-4;
			break;
		case 3: // BOTTOM
			labelPosX = -1;
			labelPosY = self.frame.size.height;
			break;
	}
	
	self.label.frame = CGRectMake(labelPosX, labelPosY,
		CGRectGetWidth(self.label.frame), CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = MIN(self.maxValue, MAX(value, self.minValue));
	}
	
	// set sig fig formatting to make sure 0 values are returned as "0" instead of "0.0"
	// http://stackoverflow.com/questions/13897372/nsnumberformatter-with-significant-digits-formats-0-0-incorrectly/15281611
	if(value == 0.0) {
		self.numberLabelFormatter.usesSignificantDigits = NO;
	}
	else {
		self.numberLabelFormatter.usesSignificantDigits = YES;
	}
	self.numberLabel.text = [self.numberLabelFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
	[super setValue:value];
}

- (NSString*)type {
	return @"Numberbox";
}

- (void)setNumWidth:(int)numWidth {
	[self.numberLabelFormatter setFormatWidth:numWidth];
	_numWidth = numWidth;
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	self.touchPrevY = pos.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	int diff = self.touchPrevY - pos.y;
	if(diff != 0) {
		self.value = self.value + diff;
		[self sendFloat:self.value];
	}
	self.touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	self.touchPrevY = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	self.touchPrevY = 0;
}

#pragma mark PdListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendFloat:self.value];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
	[self sendFloat:self.value];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 0) {
		if([Util isNumberIn:list at:0]) {
			[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
		}
		else if([Util isStringIn:list at:0]) {
			if(list.count > 1 && [[list objectAtIndex:0] isEqualToString:@"set"]) {
				if([Util isNumberIn:list at:1]) {
					self.value = [[list objectAtIndex:1] floatValue];
				}
			}
			else if([[list objectAtIndex:0] isEqualToString:@"bang"]) {
				[self receiveBangFromSource:source];
			}
			else {
				[self receiveSymbol:[list objectAtIndex:0] fromSource:source];
			}
		}
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	// set message sets value without sending
	if([message isEqualToString:@"set"] && arguments.count > 0 && [Util isNumberIn:arguments at:0]) {
		self.value = [[arguments objectAtIndex:0] floatValue];
	}
	else if([message isEqualToString:@"bang"]) {
		[self receiveBangFromSource:source];
	}
	else {
		[self receiveList:arguments fromSource:source];
	}

}

@end
