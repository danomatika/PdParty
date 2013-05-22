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
#import "VUMeter.h"

#import "Gui.h"
#include "z_libpd.h"
#include "g_all_guis.h" // iem gui

#define VU_PAD_W	2
#define VU_PAD_H	4
#define VU_MAX_SCALE_CHAR_WIDTH	4

#pragma mark MeterView

// helper class, useful for future possible hit tests ...
@interface MeterView : UIView

@property (weak, nonatomic) VUMeter* parent;
@property (assign, nonatomic) int rmsBar;		// max rms led bar index
@property (assign, nonatomic) int peakBar;		// peak led bar index
@property (assign, nonatomic) CGSize barSize;	// led bar size

- (void)reshapeForGui:(Gui *)gui;

@end

#pragma mark VUMeter

@interface VUMeter ()

@property (assign) BOOL isDefaultFillColor;
@property (weak) MeterView *meterView;
@property (assign) float scaleX; // current gui.scaleX

@end

@implementation VUMeter

+ (id)vumeterFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 16) { // sanity check
		DDLogWarn(@"VUMeter: Cannot create, atom line length < 16");
		return nil;
	}

	VUMeter *v = [[VUMeter alloc] initWithFrame:CGRectZero];
	
	v.receiveName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
	if(![v hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"VUMeter: Dropping, receive name is empty");
		return nil;
	}
	
	// constrain height to multiples of IEM_VU_STEPS
	v.originalFrame = CGRectMake(
		[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
		[[line objectAtIndex:5] floatValue],
		floor([[line objectAtIndex:6] floatValue] / IEM_VU_STEPS) * IEM_VU_STEPS);
	
	v.label.text = [Gui filterEmptyStringValues:[line objectAtIndex:8]];
	v.originalLabelPos = CGPointMake([[line objectAtIndex:9] floatValue], [[line objectAtIndex:10] floatValue]);
	v.labelFontSize = [[line objectAtIndex:12] floatValue];

	v.fillColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:13] integerValue]];
	v.label.textColor = [IEMWidget colorFromIEMColor:[[line objectAtIndex:14] integerValue]];

	v.showScale = [[line objectAtIndex:15] boolValue];

	[v reshapeForGui:gui];
	
	return v;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
	
		self.showScale = YES;
		self.scaleX = 1.0;
		self.isDefaultFillColor = NO;
		
		MeterView *m = [[MeterView alloc] initWithFrame:CGRectZero];
		m.parent = self;
		self.meterView = m;
		[self addSubview:m];
	}
    return self;
}

- (void)reshapeForGui:(Gui *)gui {
	
	self.scaleX = gui.scaleX;
	
	// meter
	[self.meterView reshapeForGui:gui];
	
	// bounds from meter size + optional scale width
	CGRect bounds = CGRectMake(
		round(self.originalFrame.origin.x * gui.scaleX),
		round(self.originalFrame.origin.y * gui.scaleY),
		CGRectGetWidth(self.meterView.frame),
		CGRectGetHeight(self.meterView.frame));
	if(self.showScale) {
		CGSize charSize = [@"0" sizeWithFont:self.label.font]; // assumes monospaced font
		bounds.size.width += (charSize.width * VU_MAX_SCALE_CHAR_WIDTH) + 1;
		bounds.size.height += self.labelFontSize;
		bounds.origin.y -= self.labelFontSize/2;
	}
	self.frame = bounds;
	
	// label
	[self reshapeLabelForGui:gui];
	if(self.showScale) { // shift label down slightly since meter is shifted down
		CGRect labelFrame = self.label.frame;
		labelFrame.origin.y += self.meterView.frame.origin.y;
		self.label.frame = labelFrame;
	}
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	
	// vu scale text
	if(self.showScale) {
		CGPoint pos = CGPointMake(round(CGRectGetWidth(self.meterView.frame) + 1), 0);
		int k1 = self.meterView.barSize.height+1, k2 = IEM_VU_STEPS+1, k3 = k1/2;
		int k4 = -k3;
		for(int i = 0; i <= IEM_VU_STEPS+1; ++i) {
			pos.y = round((k4 + k1*(k2-i)) - (VU_PAD_H/2));
			NSString * vuString = [NSString stringWithUTF8String:iemgui_vu_scale_str[i+1]];
			if(vuString.length > 0) {
				CGPoint stringPos = CGPointMake(pos.x,//(2*self.scaleX)),
				round(pos.y * self.scaleX));
				CGContextSetFillColorWithColor(context, self.label.textColor.CGColor);
				[vuString drawAtPoint:stringPos withFont:self.label.font];
			}
		}
	}
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
    int i;
	if(f <= IEM_VU_MINDB) {
        self.meterView.rmsBar = 0;
    }
	else if(f >= IEM_VU_MAXDB) {
        self.meterView.rmsBar = IEM_VU_STEPS;
    }
	else {
        i = (int)(2.0 * (f + IEM_VU_OFFSET));
        self.meterView.rmsBar = iemgui_vu_db2i[i];
    }
    i = (int)((100.0 * f) + 10000.5);
    [super setValue:(0.01 * (i - 10000))];
	[self.meterView setNeedsDisplay];
}


- (void)setPeakValue:(float)peakValue {
    int i;
    if(peakValue <= IEM_VU_MINDB) {
        self.meterView.peakBar = 0;
	}
    else if(peakValue >= IEM_VU_MAXDB) {
        self.meterView.peakBar = IEM_VU_STEPS;
	}
    else {
        i = (int)(2.0 * (peakValue + IEM_VU_OFFSET));
        self.meterView.peakBar = iemgui_vu_db2i[i];
    }
    i = (int)(100.0 * peakValue + 10000.5);
    _peakValue = 0.01 * (i - 10000);
	// dosen't call setNeedsDisplay,
	// rms & peak values come in pairs so only redisplay once when setting rms
}

- (void)setFillColor:(UIColor *)fillColor {
	CGFloat r, g, b, a;
	[fillColor getRed:&r green:&g blue:&b alpha:&a];
	if(r == 0.250980  && g == 0.250980 && b == 0.250980 && a == 1.0) { // check for default color value
		[super setFillColor:[UIColor colorWithWhite:0.25 alpha:1.0]];
		self.isDefaultFillColor = YES;
	}
	else {
		[super setFillColor:fillColor];
		self.isDefaultFillColor = NO;
	}
}

- (NSString *)type {
	return @"VUMeter";
}

#pragma mark WidgetListener

- (void)receiveBangFromSource:(NSString *)source {
// no sendName
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	self.value = received;
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	if(list.count > 1) {
		if([list isNumberAt:0] && [list isNumberAt:1]) {
			self.peakValue = [[list objectAtIndex:1] floatValue];
			self.value = [[list objectAtIndex:0] floatValue];
		}
	}
	else {
		[super receiveList:list fromSource:source];
	}
}

@end

#pragma mark MeterView

@implementation MeterView

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.barSize = CGSizeMake(IEM_VU_DEFAULTSIZE * 2, IEM_VU_DEFAULTSIZE);
	}
    return self;
}

- (void)reshapeForGui:(Gui *)gui {

	// bounds
	CGRect bounds = CGRectMake(0, 0,
		round((CGRectGetWidth(self.parent.originalFrame) + VU_PAD_W + 1) * gui.scaleX),
		round((CGRectGetHeight(self.parent.originalFrame) + VU_PAD_H + 1) * gui.scaleX));
	if(self.parent.showScale) {
		bounds.origin.y = round(self.parent.labelFontSize/2); // offset for scale text
	}
	self.frame = bounds;

	// led bar
	self.barSize = CGSizeMake(
		round(((CGRectGetWidth(self.parent.originalFrame)/2) - 1)),
		round(((CGRectGetHeight(self.parent.originalFrame) / IEM_VU_STEPS) - 1)));
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
	CGContextSetLineWidth(context, 1.0);
	
	// background
	CGContextSetFillColorWithColor(context, self.parent.fillColor.CGColor);
	CGContextFillRect(context, rect);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.parent.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1));
	
	// led bars
	CGPoint pos = CGPointMake(round(rect.size.width/4) - 1, 0);
	int k1 = self.barSize.height+1, k2 = IEM_VU_STEPS+1, k3 = k1/2;
    int k4 = -k3;
	for(int i = 1; i <= IEM_VU_STEPS; ++i) {
		if(i == self.peakBar || i <= self.rmsBar) {
			pos.y = k4 + k1*(k2-i) - 1;
			CGRect bar;
			if(i == self.peakBar) {
				bar = CGRectMake(1, round(pos.y * self.parent.scaleX),
					round(CGRectGetWidth(rect)-3),
					round((self.barSize.height+1) * self.parent.scaleX));
			}
			else {
				bar = CGRectMake(pos.x, round(pos.y * self.parent.scaleX),
					round(CGRectGetWidth(rect)/2 + 1),
					round((self.barSize.height+1) * self.parent.scaleX));
			}
			UIColor *barColor = [IEMWidget colorFromIEMColor:iemgui_vu_col[i]];
			CGContextSetFillColorWithColor(context, barColor.CGColor);
			CGContextSetStrokeColorWithColor(context, barColor.CGColor);
			CGContextFillRect(context, bar);
			CGContextStrokeRect(context, bar);
		}
	}
}

@end
