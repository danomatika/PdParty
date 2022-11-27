/*
 * Copyright (c) 2013,2020-22 Dan Wilcox <danomatika@gmail.com>
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
@property (strong, nonatomic) UIView *inputView; ///< key input subview
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
#ifdef DEBUG_KEYGRABBER
	#ifdef KEYGRABBER_PRESSES
	if([self.inputView isKindOfClass:PressesGrabber.class] ) {
		DDLogVerbose(@"KeyGrabberView: Presses backend");
	}
	else
	#endif
	{
		DDLogVerbose(@"KeyGrabberView: UIKeyInput backend");
	}
#endif
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
			unichar key = [PressesGrabber characterForPress:press];
			NSString *name = [PressesGrabber nameForPress:press];
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses began %d %@", (int)key, name);
				DDLogVerbose(@"KeyGrabberView: code %ldl chars \"%@\"",
					(long)press.key.keyCode, press.key.characters);
			#endif
			[self.parent.delegate keyPressed:(int)key];
			[self.parent.delegate keyName:name pressed:YES];
		}
	}
	[super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
	if(self.parent.delegate) {
		for(UIPress *press in presses) {
			unichar key = [PressesGrabber characterForPress:press];
			NSString *name = [PressesGrabber nameForPress:press];
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses ended %d %@", (int)key, name);
				DDLogVerbose(@"KeyGrabberView: code %ldl chars %@",
					(long)press.key.keyCode, press.key.characters);
			#endif
			[self.parent.delegate keyReleased:(int)key];
			[self.parent.delegate keyName:name pressed:NO];
		}
	}
	[super pressesEnded:presses withEvent:event];
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
	if(self.parent.delegate) {
		for(UIPress *press in presses) {
			unichar key = [PressesGrabber characterForPress:press];
			NSString *name = [PressesGrabber nameForPress:press];
			#ifdef DEBUG_KEYGRABBER
				DDLogVerbose(@"KeyGrabberView: presses cancelled %d %@", (int)key, name);
				DDLogVerbose(@"KeyGrabberView: code %ldl chars %@",
					(long)press.key.keyCode, press.key.characters);
			#endif
			[self.parent.delegate keyReleased:(int)key];
			[self.parent.delegate keyName:name pressed:NO];
		}
	}
	[super pressesCancelled:presses withEvent:event];
}

+ (unichar)characterForPress:(UIPress *)press {
	unichar key = 0;
	NSString *chars = press.key.characters;
	if(chars && ![chars isEqualToString:@""]) {
		key = [chars characterAtIndex:0];
	}
	return key;
}

// set names to match Tk https://tcl.tk/man/tcl8.6/TkCmd/keysyms.html
+ (NSString *)nameForPress:(UIPress *)press {

	// known key codes from UIKeyConstants.h
	switch(press.key.keyCode) {

		// main
		case UIKeyboardHIDUsageKeyboardReturnOrEnter     : return @"Return";
		case UIKeyboardHIDUsageKeyboardEscape            : return @"Escape";
		case UIKeyboardHIDUsageKeyboardDeleteOrBackspace : return @"BackSpace";
		case UIKeyboardHIDUsageKeyboardTab               : return @"Tab";
		case UIKeyboardHIDUsageKeyboardSpacebar          : return @"Space";
		case UIKeyboardHIDUsageKeyboardCapsLock          : return @"Caps Lock";

		// function keys
		case UIKeyboardHIDUsageKeyboardF1            : return @"F1";
		case UIKeyboardHIDUsageKeyboardF2            : return @"F2";
		case UIKeyboardHIDUsageKeyboardF3            : return @"F3";
		case UIKeyboardHIDUsageKeyboardF4            : return @"F4";
		case UIKeyboardHIDUsageKeyboardF5            : return @"F5";
		case UIKeyboardHIDUsageKeyboardF6            : return @"F6";
		case UIKeyboardHIDUsageKeyboardF7            : return @"F7";
		case UIKeyboardHIDUsageKeyboardF8            : return @"F8";
		case UIKeyboardHIDUsageKeyboardF9            : return @"F9";
		case UIKeyboardHIDUsageKeyboardF10           : return @"F10";
		case UIKeyboardHIDUsageKeyboardF11           : return @"F11";
		case UIKeyboardHIDUsageKeyboardF12           : return @"F12";
		case UIKeyboardHIDUsageKeyboardPrintScreen   : return @"Print";
		case UIKeyboardHIDUsageKeyboardScrollLock    : return @"Scroll_Lock";
		case UIKeyboardHIDUsageKeyboardPause         : return @"Pause";
		case UIKeyboardHIDUsageKeyboardInsert        : return @"Insert";
		case UIKeyboardHIDUsageKeyboardHome          : return @"Home";
		case UIKeyboardHIDUsageKeyboardPageUp        : return @"Next";
		case UIKeyboardHIDUsageKeyboardDeleteForward : return @"Delete";
		case UIKeyboardHIDUsageKeyboardEnd           : return @"End";
		case UIKeyboardHIDUsageKeyboardPageDown      : return @"Prior";
		case UIKeyboardHIDUsageKeyboardRightArrow    : return @"Right";
		case UIKeyboardHIDUsageKeyboardLeftArrow     : return @"Left";
		case UIKeyboardHIDUsageKeyboardDownArrow     : return @"Down";
		case UIKeyboardHIDUsageKeyboardUpArrow       : return @"Up";

		// keypad / numpad
		case UIKeyboardHIDUsageKeypadNumLock         : return @"Clear";
		case UIKeyboardHIDUsageKeypadEnter           : return @"Return";

		// additional keys
		case UIKeyboardHIDUsageKeyboardF13           : return @"F13";
		case UIKeyboardHIDUsageKeyboardF14           : return @"F14";
		case UIKeyboardHIDUsageKeyboardF15           : return @"F15";
		case UIKeyboardHIDUsageKeyboardF16           : return @"F16";
		case UIKeyboardHIDUsageKeyboardF17           : return @"F17";
		case UIKeyboardHIDUsageKeyboardF18           : return @"F18";
		case UIKeyboardHIDUsageKeyboardF19           : return @"F19";
		case UIKeyboardHIDUsageKeyboardF20           : return @"F20";

		// modifiers
		case UIKeyboardHIDUsageKeyboardLeftControl   : return @"Control_L";
		case UIKeyboardHIDUsageKeyboardLeftShift     : return @"Shift_L";
		case UIKeyboardHIDUsageKeyboardLeftAlt       : return @"Alt_L";
		case UIKeyboardHIDUsageKeyboardLeftGUI       : return @"Meta_L";
		case UIKeyboardHIDUsageKeyboardRightControl  : return @"Control_R";
		case UIKeyboardHIDUsageKeyboardRightShift    : return @"Shift_R";
		case UIKeyboardHIDUsageKeyboardRightAlt      : return @"Alt_R";
		case UIKeyboardHIDUsageKeyboardRightGUI      : return @"Meta_R";

		// pass the rest through, ie. printable "a", "A", etc
		// non-printable characters will already be an empty string
		default: return press.key.characters;
	}
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
