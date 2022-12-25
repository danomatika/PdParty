#import "TextViewLogger.h"

#define MAX_LINES 1000

@interface TextViewLogger () {}
@property (strong, readwrite, atomic) NSMutableString *text;
@property (readwrite, atomic) NSInteger lineCount;
@end

@implementation TextViewLogger

- (id)init {
	self = [super init];
	if(self) {
		self.text = [NSMutableString string];
		self.lineCount = 0;
		self.animateScroll = NO;
	}
	return self;
}

- (void)addLine:(NSString*)line {
	@synchronized(self) {
		// append & catch any embedded endlines
		[self.text appendFormat:@"%@%@", (self.lineCount > 0 ? @"\n" : @""), line];
		self.lineCount += [[line componentsSeparatedByString:@"\n"] count];
		
		// pop oldest lines
		while(self.lineCount >= MAX_LINES) {
			NSRange endline = [self.text rangeOfString:@"\n"];
			[self.text deleteCharactersInRange:NSMakeRange(0, endline.location+1)];
			self.lineCount--;
		}
		
		// update textview, if any
		[self update];
	}
}

- (void)update {
	@synchronized(self) {
		if(self.textView) {
			dispatch_async(dispatch_get_main_queue(), ^{
				BOOL scroll = NO;
				int contentHeight = self.textView.contentSize.height - self.textView.font.lineHeight*2;
				// scroll up for new lines if we're not scrolling and within the last 2 lines
				if((contentHeight >= CGRectGetHeight(self.textView.bounds)) &&
				   (!self.textView.tracking && !self.textView.dragging &&
				    !self.textView.decelerating && !self.textView.zooming) &&
				   (CGRectGetHeight(self.textView.bounds) + self.textView.contentOffset.y >= contentHeight)) {
					scroll = YES;
				}
				[self updateText];
				if(scroll) {
					if(self.animateScroll) {
						[self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length-1, 1)];
					}
					else {
						// from http://stackoverflow.com/questions/29022962/scroll-uitextview-to-bottom-without-animation
						CGPoint bottomOffset = CGPointMake(0, self.textView.contentSize.height - self.textView.bounds.size.height);
						[self.textView setContentOffset:bottomOffset animated:NO];
					}
				}
			});
		}
	}
}

- (void)clear {
	@synchronized(self) {
		if(self.textView) {
			self.textView.text = @"";
		}
		[self.text setString:@""];
		self.lineCount = 0;
	}
}

#pragma mark Logger

- (void)logMessage:(NSString *)message {
	if(!message) {return;}
	@synchronized(self) {
		[self addLine:message];
	}
}

#pragma mark Overridden Getters/Setters

- (void)setTextView:(UITextView *)textView {
	_textView = textView;
	[self update];
}

#pragma mark Private

- (void)updateText {
	// temporarily disable scrolling to avoid occasional bug that causes text
	// view being cut off towards the top: http://stackoverflow.com/a/19797795/2146055
	BOOL enabled = self.textView.scrollEnabled;
		self.textView.scrollEnabled = NO;
		self.textView.text = self.text;
	self.textView.scrollEnabled = enabled;
}

@end
