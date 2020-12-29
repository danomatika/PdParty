/*
 * Copyright (c) 2013,2020 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "KeyGrabber.h"

#import "Log.h"

#define DEBUG_KEYGRABBER

// add PressGrabber when compiling with iOS 13.4+ SDK
#ifdef __IPHONE_13_4
#define KEYGRABBER_PRESSES
#endif

#ifdef KEYGRABBER_PRESSES

/// key event backend using UIPresses events, keyPressed & keyReleased
@interface PressesGrabber : UIView
@property (weak, nonatomic) KeyGrabberView *parent;
@end

#endif

/// key event backend using UIKeyInput protocol, keyPressed only
@interface KeyInputGrabber : UIView <UIKeyInput>
@property (weak, nonatomic) KeyGrabberView *parent;
@end

#pragma mark KeyGrabberView

@interface KeyGrabberView ()
@property (strong, nonatomic) UIView *inputView; //< key input subview
@end

@implementation KeyGrabberView

// prefer PressesGrabber when available, otherwise fall back to KeyInputGrabber
- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
#ifdef KEYGRABBER_PRESSES
	if(@available(iOS 13.4, *)) {
		PressesGrabber *inputView = [[PressesGrabber alloc] initWithFrame:CGRectZero];
		inputView.parent = self;
		self.inputView = inputView;
		DDLogVerbose(@"KeyGrabberView: using Presses backend");
	}
	else
#endif
	{
		KeyInputGrabber *inputView = [[KeyInputGrabber alloc] initWithFrame:CGRectZero];
		inputView.parent = self;
		self.inputView = inputView;
		DDLogVerbose(@"KeyGrabberView: using UIKeyInput backend");
	}
	[self addSubview:self.inputView];
	[NSNotificationCenter.defaultCenter addObserver:self
	                                       selector:@selector(didEnterBackground)
	                                           name:UIApplicationDidEnterBackgroundNotification
	                                         object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
	                                       selector:@selector(didBecomeActive)
	                                           name:UIApplicationDidBecomeActiveNotification
	                                         object:nil];
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self
	                                              name:UIApplicationDidEnterBackgroundNotification
	                                            object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self
	                                              name:UIApplicationDidBecomeActiveNotification
	                                            object:nil];
}

- (void)didEnterBackground {
	if(self.active) {
		[self.inputView resignFirstResponder];
	}
}

- (void)didBecomeActive {
	if(self.active) {
		[self.inputView becomeFirstResponder];
	}
}

#pragma mark Overridden Getters/Setters

- (void)setActive:(BOOL)value {
	if(self.active == value) {
		return;
	}
	_active = value;
	if(self.active) {
		[self.inputView becomeFirstResponder];
	} else {
		[self.inputView resignFirstResponder];
	}
//#ifdef KEYGRABBER_PRESSES
//	if(self.inputView isKindOfClass:PressesGrabber) {
//		DDLogVerbose(@"KeyGrabberView: Presses backend");
//	}
//	else
//#endif
//	{
//		DDLogVerbose(@"KeyGrabberView: UIKeyInput backend");
//	}
}

@end

#ifdef KEYGRABBER_PRESSES

// ref: https://swiftbysundell.com/tips/handling-keyup-and-keydown-events/
@implementation PressesGrabber

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
	if(self.parent.delegate) {
		for(UIPress *press in presses) {
			unichar key = press.key.keyCode;
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses began %d", (int)key);
			#endif
			[self.parent.delegate keyPressed:(int)key];
		}
	}
	[super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
	if(self.parent.delegate) {
		for(UIPress *press in presses) {
			unichar key = press.key.keyCode;
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses ended %d", (int)key);
			#endif
			[self.parent.delegate keyReleased:(int)key];
		}
	}
	[super pressesEnded:presses withEvent:event];
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
	if(self.parent.delegate) {
		for(UIPress *press in presses) {
			unichar key = press.key.keyCode;
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses cancelled %d", (int)key);
			#endif
			[self.parent.delegate keyReleased:(int)key];
		}
	}
	[super pressesCancelled:presses withEvent:event];
}

@end

#endif

// ref: https://github.com/scarnie/iCade-iOS/tree/master/iCadeTest/iCade
@implementation KeyInputGrabber

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)hasText {
	return NO;
}

- (void)insertText:(NSString *)theText {
	unichar key = [theText characterAtIndex:0];
	#ifdef DEBUG_KEYGRABBER
		DDLogVerbose(@"KeyGrabberView: insert text \"%@\" %d", theText, key);
	#endif
	if(self.parent.delegate) {
		[self.parent.delegate keyPressed:(int)key];
	}
}

// translate to ASCII Backspace char value
- (void)deleteBackward {
	#ifdef DEBUG_KEYGRABBER
		DDLogVerbose(@"KeyGrabberView: delete backward 8");
	#endif
	if(self.parent.delegate) {
		[self.parent.delegate keyPressed:8];
	}
}

@end
