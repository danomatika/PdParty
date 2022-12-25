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
#import "Symbol.h"

#import "Gui.h"

@implementation Symbol

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 11) { // sanity check
		LogWarn(@"Symbol: cannot create, atom line length < 11");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.sendName = [Gui filterEmptyStringValues:line[10]];
		self.receiveName = [Gui filterEmptyStringValues:line[9]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			LogVerbose(@"Symbol: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			0, 0); // size based on valueWidth

		self.valueWidth = [line[4] intValue];
		self.minValue = [line[5] floatValue];
		self.maxValue = [line[6] floatValue];
		self.symbol = @"";
			
		self.labelPos = [line[7] intValue];
		self.label.text = [Gui filterEmptyStringValues:line[8]];
	}
	return self;
}

#pragma mark Overridden Getters / Setters

// catch empty string to keep label height
- (void)setSymbol:(NSString *)symbol {
	self.valueLabel.text = ([symbol isEqualToString:@""] ? @" " : symbol);
	if(self.valueWidth == 0) {
		[self reshape];
	}
	[self setNeedsDisplay];
}

- (NSString *)symbol {
	return self.valueLabel.text;
}

- (NSString *)type {
	return @"Symbol";
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self sendSymbol:self.symbol];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.symbol = @"float";
	[self sendSymbol:self.symbol];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	self.symbol = symbol;
	[self sendSymbol:self.symbol];
}

- (void)receiveSetFloat:(float)received {
	self.symbol = @"float";
}

- (void)receiveSetSymbol:(NSString *)symbol {
	self.symbol = symbol;
}

@end
