/*
 * Copyright (c) 2022 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "List.h"

#import "Gui.h"

@implementation List

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 11) { // sanity check
		DDLogWarn(@"List: cannot create, atom line length < 11");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.sendName = [Gui filterEmptyStringValues:line[10]];
		self.receiveName = [Gui filterEmptyStringValues:line[9]];
		if(![self hasValidSendName] && ![self hasValidReceiveName]) {
			// drop something we can't interact with
			DDLogVerbose(@"List: dropping, send/receive names are empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[line[2] floatValue], [line[3] floatValue],
			0, 0); // size based on valueWidth

		self.valueWidth = [line[4] intValue];
		self.minValue = [line[5] floatValue];
		self.maxValue = [line[6] floatValue];
		self.list = @[];

		self.labelPos = [line[7] intValue];
		self.label.text = [Gui filterEmptyStringValues:line[8]];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);

	// bounds as path
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-cornerSize, 0);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, cornerSize);
	CGPathAddLineToPoint(path, NULL, rect.size.width-1, rect.size.height-cornerSize);
	CGPathAddLineToPoint(path, NULL, rect.size.width-cornerSize, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, rect.size.height-1);
	CGPathAddLineToPoint(path, NULL, 0, 0);

	// background
	CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
	CGContextAddPath(context, path);
	CGContextFillPath(context);

	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);

	CGPathRelease(path);
}

#pragma mark Overridden Getters / Setters

// catch empty list to keep label height
- (void)setList:(NSArray *)list {
	_list = list;
	self.valueLabel.text = (list.count == 0 ? @" " : [list componentsJoinedByString:@" "]);
	if(self.valueWidth == 0) {
		[self reshape];
	}
	[self setNeedsDisplay];
}

- (NSString *)type {
	return @"List";
}

#pragma mark WidgetListener

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.list = @[@(received)];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	self.list = @[symbol];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if([list isStringAt:0]) {
		if([list[0] isEqualToString:@"set"]) {
			NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, list.count-1)];
			self.list = [list objectsAtIndexes:set];
			return;
		}
		else if([list[0] isEqualToString:@"bang"]) {
			return;
		}
	}
	self.list = list;
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	if([message isEqualToString:@"set"]) {
		self.list = arguments;
	}
	else if([message isEqualToString:@"bang"]) {
		return;
	}
}

@end
