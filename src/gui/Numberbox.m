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
		DDLogWarn(@"Cannot create Numberbox, atom line length < 11");
		return nil;
	}

	int numWidth = [[line objectAtIndex:4] integerValue];

	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		round(((numWidth-2) * gui.fontSize) + 3),
		round(gui.fontSize + 8));

	Numberbox *n = [[Numberbox alloc] initWithFrame:frame];

	n.sendName = [gui formatAtomString:[line objectAtIndex:10]];
	n.receiveName = [gui formatAtomString:[line objectAtIndex:9]];
	if(![n hasValidSendName] && ![n hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Dropping Numberbox, send/receive names are empty");
		return nil;
	}

	n.minValue = [[line objectAtIndex:5] floatValue];
	n.maxValue = [[line objectAtIndex:6] floatValue];
	n.numWidth = numWidth;
	n.value = 0;
	
	n.numberLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	n.numberLabel.preferredMaxLayoutWidth = frame.size.width;
	n.numberLabel.frame = CGRectMake(2, 1, CGRectGetWidth(frame), CGRectGetHeight(frame));
	[n addSubview:n.numberLabel];
	
	n.label.text = [gui formatAtomString:[line objectAtIndex:8]];
	if(![n.label.text isEqualToString:@""]) {
		
		n.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
		[n.label sizeToFit];
		
		// set the label pos from the LRUD setting
		int labelPosX, labelPosY;
		switch([[line objectAtIndex:7] integerValue]) {
			default: // 0 LEFT
				labelPosX = -gui.fontSize*(n.label.text.length-2);
				labelPosY = 0;
				break;
			case 1: // RIGHT
				labelPosX = frame.size.width+1;
				labelPosY = 0;
				break;
			case 2: // TOP
				labelPosX = -1;
				labelPosY = -gui.fontSize-4;
				break;
			case 3: // BOTTOM
				labelPosX = -1;
				labelPosY = frame.size.height;
				break;
		}
		
		n.label.frame = CGRectMake(labelPosX, labelPosY,
			CGRectGetWidth(n.label.frame), CGRectGetHeight(n.label.frame));
		[n addSubview:n.label];
	}
	return n;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		
		self.numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.numberLabel setTextAlignment:NSTextAlignmentLeft];
		self.numberLabel.backgroundColor = [UIColor clearColor];
		
		self.numberLabelFormatter = [[NSNumberFormatter alloc] init];
		[self.numberLabelFormatter setPaddingCharacter:@" "];
		[self.numberLabelFormatter setPaddingPosition:NSNumberFormatterPadAfterSuffix];
		
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

#pragma mark Overridden Getters & Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = MIN(self.maxValue, MAX(value, self.minValue));
	}
	self.numberLabel.text = [self.numberLabelFormatter stringFromNumber:[NSNumber numberWithFloat:value]];
	[super setValue:value];
}

- (NSString*)type {
	return @"Numberbox";
}

- (void)setNumWidth:(int)numWidth {
	[self.numberLabelFormatter setFormatWidth:numWidth];
	_numWidth = numWidth;
}

#pragma mark - Touches

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
	if(list.count > 0 && [Util isNumberIn:list at:0]) {
		[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
	}
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	// set message sets value without sending
	if([message isEqualToString:@"set"] && arguments.count > 0 && [Util isNumberIn:arguments at:0]) {
		self.value = [[arguments objectAtIndex:0] floatValue];
	}
}

@end
