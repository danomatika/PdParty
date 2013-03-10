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
	int touchPrevY;
}
@end

@implementation Numberbox

+ (id)numberboxFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

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

	n.valueWidth = [[line objectAtIndex:4] integerValue];
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
		
		self.valueLabelFormatter = [[NSNumberFormatter alloc] init];
		//self.valueLabelFormatter.numberStyle = NSNumberFormatterScientificStyle;
		self.valueLabelFormatter.maximumSignificantDigits = 6;
		self.valueLabelFormatter.paddingCharacter = @" ";
		self.valueLabelFormatter.paddingPosition = NSNumberFormatterPadAfterSuffix;
		
		touchPrevY = 0;
    }
    return self;
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)value {
	if(self.minValue != 0 || self.maxValue != 0) {
		value = MIN(self.maxValue, MAX(value, self.minValue));
	}
	
	// set sig fig formatting to make sure 0 values are returned as "0" instead of "0.0"
	// http://stackoverflow.com/questions/13897372/nsnumberformatter-with-significant-digits-formats-0-0-incorrectly/15281611
	if(value == 0.0) {
		self.valueLabelFormatter.usesSignificantDigits = NO;
	}
	else {
		self.valueLabelFormatter.usesSignificantDigits = YES;
	}
	self.valueLabel.text = [self.valueLabelFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
	[super setValue:value];
}

- (NSString *)type {
	return @"Numberbox";
}

- (void)setValueWidth:(int)valueWidth {
	[self.valueLabelFormatter setFormatWidth:valueWidth];
	[super setValueWidth:valueWidth];
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	touchPrevY = pos.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
	int diff = touchPrevY - pos.y;
	if(diff != 0) {
		self.value = self.value + diff;
		[self sendFloat:self.value];
	}
	touchPrevY = pos.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchPrevY = 0;
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
