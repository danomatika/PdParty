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
#import "Comment.h"

#import "Gui.h"

@implementation Comment

+ (id)commentFromAtomLine:(NSArray*)line withGui:(Gui*)gui {

	// create the comment string
	NSMutableString *text = [[NSMutableString alloc] init];
	for(int i = 4; i < line.count; ++i) {
		[text appendString:[line objectAtIndex:i]];
		if(i < line.count - 1) {
			[text appendString:@" "];
		}
	}
	
	// create label and size to fit based on pd gui's line wrap at 60 chars
	UIFont *labelFont = [UIFont systemFontOfSize:gui.fontSize];
	UILabel *label = [[UILabel alloc] init];
	label.text = text;
	label.font = labelFont;
	label.numberOfLines = 0; // allow line wrapping
	label.preferredMaxLayoutWidth = gui.fontSize * 60; // pd gui wraps at 60 chars
	[label sizeToFit];
	
	// create label based on computed label size
	CGRect frame = CGRectMake(
		round([[line objectAtIndex:2] floatValue] * gui.scaleX),
		round([[line objectAtIndex:3] floatValue] * gui.scaleY),
		CGRectGetWidth(label.frame),
		CGRectGetHeight(label.frame));
	
	Comment *c = [[Comment alloc] initWithFrame:frame];

	c.label = label;
	[c addSubview:c.label];
	
	//setupReceive();
	//ofAddListener(ofEvents.mousePressed, this, &Toggle::mousePressed);
	
	return c;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if (self) {
        self.fillColor = WIDGET_FILL_COLOR;
        self.frameColor = WIDGET_FRAME_COLOR;
    }
    return self;
}

//- (void)drawRect:(CGRect)rect {
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
//    CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
//	CGContextSetLineWidth(context, 1.0);
//	
//    CGRect frame = rect;
//	
//	// border
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, 0, 0);
//	CGContextAddLineToPoint(context, frame.size.width-1, 0);
//    CGContextAddLineToPoint(context, frame.size.width-1, frame.size.height-1);
//	CGContextAddLineToPoint(context, 0, frame.size.height-1);
//	CGContextAddLineToPoint(context, 0, 0);
//    CGContextStrokePath(context);
//
//	// bang
//	CGRect circleFrame = CGRectMake(1, 1, frame.size.width-3, frame.size.height-3);
//	CGContextStrokeEllipseInRect(context, circleFrame);
//}

- (NSString*) getType {
	return @"Comment";
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	
//    UITouch *touch = [touches anyObject];
//    CGPoint pos = [touch locationInView:self];
//	
//    [self mapPointToValue:pos];
//    [self setNeedsDisplay]; // TODO: the drawing commands in drawRect don't get erased by this command only
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint pos = [touch locationInView:self];
//	if ([self pointIsWithinBounds:pos]) {
//		[self mapPointToValue:pos];
//	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end

//
//
//#include "Gui.h"
//
//namespace gui {
//
//const string Comment::s_type = "Comment";
//
//Comment::Comment(Gui& parent, const AtomLine& atomLine) : Widget(parent) {
//
//	// create the comment string
//	ostringstream text;
//	for(int i = 4; i < atomLine.size(); ++i) {
//		text << atomLine[i];
//		if(i < atomLine.size() - 1) {
//			text << " ";
//		}
//	}
//
//	label = text.str();
//	labelPos.x = ofToFloat(atomLine[2]) / parent.patchWidth * parent.width;
//	labelPos.y = ofToFloat(atomLine[3]) / parent.patchHeight * parent.height + parent.fontSize;
//}
//
//void Comment::draw() {
//	drawLabel();
//}
//
//} // namespace
