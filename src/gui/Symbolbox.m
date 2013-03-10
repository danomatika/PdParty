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
#import "Symbolbox.h"

#import "Gui.h"

@implementation Symbolbox

+ (id)symbolboxFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 11) { // sanity check
		DDLogWarn(@"Symbolbox: Cannot create, atom line length < 11");
		return nil;
	}

	Symbolbox *s = [[Symbolbox alloc] initWithFrame:CGRectZero];

	s.sendName = [gui formatAtomString:[line objectAtIndex:10]];
	s.receiveName = [gui formatAtomString:[line objectAtIndex:9]];
	if(![s hasValidSendName] && ![s hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Symbolbox: Dropping, send/receive names are empty");
		return nil;
	}
	
	s.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on numwidth

	s.valueWidth = [[line objectAtIndex:4] integerValue] - 1;
	s.minValue = [[line objectAtIndex:5] floatValue];
	s.maxValue = [[line objectAtIndex:6] floatValue];
	s.symbol = @"symbol";
		
	s.labelPos = [[line objectAtIndex:7] integerValue];
	s.label.text = [gui formatAtomString:[line objectAtIndex:8]];

	[s reshapeForGui:gui];

	return s;
}

#pragma mark Overridden Getters / Setters

- (void)setSymbol:(NSString *)symbol {
	self.valueLabel.text = symbol;
	[self setNeedsDisplay];
}

- (NSString *)symbol {
	return self.valueLabel.text;
}

- (NSString *)type {
	return @"Symbolbox";
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
	[self send:self.symbol];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.symbol = @"float";
	[self send:self.symbol];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	self.symbol = symbol;
	[self send:self.symbol];
}

- (void)receiveSetFloat:(float)received {
	self.symbol = @"float";
}

- (void)receiveSetSymbol:(NSString *)symbol {
	self.symbol = symbol;
}

@end
