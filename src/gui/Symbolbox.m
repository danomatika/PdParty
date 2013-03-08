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

+ (id)symbolboxFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

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

	s.symWidth = [[line objectAtIndex:4] integerValue];
	s.minValue = [[line objectAtIndex:5] floatValue];
	s.maxValue = [[line objectAtIndex:6] floatValue];
	s.symbol = @"symbol";
		
	s.labelPos = [[line objectAtIndex:7] integerValue];
	s.label.text = [gui formatAtomString:[line objectAtIndex:8]];

	[s reshapeForGui:gui];

	return s;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.symbolLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.symbolLabel setTextAlignment:NSTextAlignmentLeft];
		self.symbolLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.symbolLabel];
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
		round(((self.symWidth-2) * gui.fontSize) + 3),
		round(gui.fontSize + 8));
		
	// symbol label
	self.symbolLabel.font = [UIFont fontWithName:GUI_FONT_NAME size:gui.fontSize];
	self.symbolLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.frame);
	self.symbolLabel.frame = CGRectMake(2, 1, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));

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

- (void)setSymbol:(NSString *)symbol {
	self.symbolLabel.text = symbol;
	[self setNeedsDisplay];
}

- (NSString*)symbol {
	return self.symbolLabel.text;
}

- (NSString*)type {
	return @"Symbolbox";
}

#pragma mark PdListener

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

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 0) {
		if([Util isNumberIn:list at:0]) {
			[self receiveFloat:[[list objectAtIndex:0] floatValue] fromSource:source];
		}
		else if([Util isStringIn:list at:0]) {
			if(list.count > 1 && [[list objectAtIndex:0] isEqualToString:@"set"]) {
				if([Util isNumberIn:list at:1]) {
					self.symbol = @"float";
				}
				else if([Util isStringIn:list at:1]) {
					self.symbol = [list objectAtIndex:1];
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
	if(arguments.count > 0 && [message isEqualToString:@"set"]) {
		if([Util isNumberIn:arguments at:0]) {
			self.symbol = @"float";
		}
		else if([Util isStringIn:arguments at:0]) {
			self.symbol = [arguments objectAtIndex:0];
		}
	}
	else if([message isEqualToString:@"bang"]) {
		[self receiveBangFromSource:source];
	}
	else {
		[self receiveList:arguments fromSource:source];
	}
}

@end
