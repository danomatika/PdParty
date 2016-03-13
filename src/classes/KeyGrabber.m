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
#import "KeyGrabber.h"

@interface KeyGrabberView ()
@property (strong, nonatomic) UIView *inputView;
@end

@implementation KeyGrabberView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.inputView = [[UIView alloc] initWithFrame:CGRectZero];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didEnterBackground {
	if(self.active) {
		[self resignFirstResponder];
	}
}

- (void)didBecomeActive {
	if(self.active) {
		[self becomeFirstResponder];
	}
}

- (BOOL)canBecomeFirstResponder { 
	return YES; 
}

#pragma mark Overridden Getters/Setters

- (void)setActive:(BOOL)value {
	if(self.active == value) {
		return;
	}
	_active = value;
	if(self.active) {
		[self becomeFirstResponder];
	} else {
		[self resignFirstResponder];
	}
}

#pragma mark UIKeyInput

- (BOOL)hasText {
	return NO;
}

- (void)insertText:(NSString *)theText {
	self.key = [theText characterAtIndex:0];
	//NSLog(@"char typed: [%@] %d", theText, self.key);
	if(self.delegate) {
		[self.delegate keyPressed:self.key];
	}
}

- (void)deleteBackward {
	//NSLog(@"backspace key pressed");
	self.key = 8; // ASCII Backspace char value
	if(self.delegate) {
		[self.delegate keyPressed:self.key];
	}
}

@end
