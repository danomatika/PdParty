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
#import "Radio.h"

#import "Gui.h"

@implementation Radio

+ (id)radioFromAtomLine:(NSArray *)line withOrientation:(WidgetOrientation)orientation withGui:(Gui *)gui {

	if(line.count < 19) { // sanity check
		DDLogWarn(@"Radio: Cannot create, atom line length < 19");
		return nil;
	}

	Radio *r = [[Radio alloc] initWithFrame:CGRectZero];

	r.sendName = [gui formatAtomString:[line objectAtIndex:9]];
	r.receiveName = [gui formatAtomString:[line objectAtIndex:10]];
	if(![r hasValidSendName] && ![r hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Radio: Dropping, send/receive names are empty");
		return nil;
	}
	
	r.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		0, 0); // size based on numCells
			
	r.orientation = orientation;
	r.width = [[line objectAtIndex:5] integerValue];
	r.value = [[line objectAtIndex:6] integerValue];
	r.inits = [[line objectAtIndex:7] boolValue];
	r.numCells = [[line objectAtIndex:8] integerValue];
	
	r.label.text = [gui formatAtomString:[line objectAtIndex:11]];
	r.originalLabelPos = CGPointMake([[line objectAtIndex:12] floatValue], [[line objectAtIndex:13] floatValue]);
	
	r.fillColor = [Gui colorFromIEMColor:[[line objectAtIndex:16] integerValue]];
	r.controlColor = [Gui colorFromIEMColor:[[line objectAtIndex:17] integerValue]];
	r.label.textColor = [Gui colorFromIEMColor:[[line objectAtIndex:18] integerValue]];

	[r reshapeForGui:gui];
	
	[r sendInitValue];
	
	return r;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.width = 15;
		self.numCells = 8; // don't trigger redraw yet
		self.minValue = 0;
		self.orientation = WidgetOrientationHorizontal;
    }
    return self;
}

- (void)reshapeForGui:(Gui *)gui {
	
	// bounds
	if(self.orientation == WidgetOrientationHorizontal) {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * gui.scaleX),
			round(self.originalFrame.origin.y * gui.scaleY),
			round(self.width * self.numCells * gui.scaleX),
			round(self.width * gui.scaleX));
	}
	else {
		self.frame = CGRectMake(
			round(self.originalFrame.origin.x * gui.scaleX),
			round(self.originalFrame.origin.y * gui.scaleY),
			round(self.width * gui.scaleX),
			round(self.width * self.numCells * gui.scaleX));
	}
	
	// cells, -1 for label which is at index
	if(self.subviews.count-1 != self.numCells) {
		if(self.subviews.count-1 < self.numCells) { // add
			while(self.subviews.count-1 < self.numCells) {
				RadioCell *cell = [[RadioCell alloc] initWithFrame:CGRectZero];
				cell.parent = self;
				cell.whichCell = self.subviews.count-1;
				if(cell.whichCell == self.value) {
					cell.selected = YES;
				}
				[self addSubview:cell];
			}
		}
		else { // remove
			while(self.subviews.count-1 > self.numCells) {
				[[self.subviews lastObject] removeFromSuperview];
			}
		}
	}
	
	// reshape cells
	for(int i = 1; i < self.subviews.count; ++i) {
		CGRect frame;
		if(self.orientation == WidgetOrientationHorizontal) {
			frame = CGRectMake(
				round(self.width * gui.scaleX * (i-1)), 0,
				round(self.width * gui.scaleX),
				round(self.width * gui.scaleX));
		}
		else {
			frame = CGRectMake(
				0, round(self.width * gui.scaleX * (i-1)),
				round(self.width * gui.scaleX),
				round(self.width * gui.scaleX));
		}
		[[self.subviews objectAtIndex:i] setFrame:frame];
		[[self.subviews objectAtIndex:i] setNeedsDisplay];
	}
	
	// label
	self.label.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.labelFontSize];
	[self.label sizeToFit];
	int nudgeX = 0, nudgeY = 0;
	if(self.orientation == WidgetOrientationHorizontal) {
		nudgeY = -2;
	}
	self.label.frame = CGRectMake(
		round(self.originalLabelPos.x * gui.scaleX) + nudgeX,
		round(self.originalLabelPos.y * gui.scaleY) + nudgeY,
		CGRectGetWidth(self.label.frame),
		CGRectGetHeight(self.label.frame));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	int newVal = (int) MIN(self.maxValue, MAX(self.minValue, f)); // round to int
	if(self.subviews.count > 1) { // label is at index 0, 1 & up are cells
		RadioCell *oldCell = (RadioCell *)[self.subviews objectAtIndex:(int)self.value+1];
		RadioCell *newCell = (RadioCell *)[self.subviews objectAtIndex:newVal+1];
		oldCell.selected = NO;
		newCell.selected = YES;
	}
	[super setValue:newVal];
}

- (void)setWidth:(int)width {
	_width = width;
	[self setNeedsDisplay]; // redraw with new width
}

- (void)setNumCells:(int)numCells {
	if(numCells < 1) {
		return;
	}
	_numCells = numCells;
	self.maxValue = numCells-1;
	if(numCells < self.value) {
		self.value = self.maxValue;
	}
}

- (NSString *)type {
	if(self.orientation == WidgetOrientationHorizontal) {
		return @"Radio";
	}
	return @"Radio";
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

#pragma mark RadioCell

@implementation RadioCell

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.whichCell = -1;
		self.selected = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetLineWidth(context, 1.0);
	
	// background
	CGContextSetFillColorWithColor(context, self.parent.fillColor.CGColor);
	CGContextFillRect(context, rect);
	CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.parent.frameColor.CGColor);
	if(self != [self.parent.subviews lastObject]) { // overlap borders except on last object
		if(self.parent.orientation == WidgetOrientationHorizontal) {
			CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect)-1));
		}
		else {
			CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)));
		}
	}
	else {
		CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1));
	}
	
	// selected?
	if(self.isSelected) {
		CGContextSetFillColorWithColor(context, self.parent.controlColor.CGColor);
		CGContextSetStrokeColorWithColor(context, self.parent.controlColor.CGColor);
		CGRect selectedFrame = CGRectMake(
			round(rect.origin.x + (CGRectGetWidth(rect) * 0.20)),
			round(rect.origin.y + (CGRectGetHeight(rect) * 0.20)),
			round(CGRectGetWidth(rect) * 0.60),
			round(CGRectGetHeight(rect) * 0.60));
		CGContextFillRect(context, selectedFrame);
		CGContextStrokeRect(context, selectedFrame);
	}
}

// notify the parent Radio of a hit
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.parent setValue:self.whichCell];
	[self.parent sendFloat:self.parent.value];
//	DDLogVerbose(@"RadioCell %d hit", self.whichCell);
}

- (void)setSelected:(BOOL)selected {
	_selected = selected;
	[self setNeedsDisplay];
}

@end
