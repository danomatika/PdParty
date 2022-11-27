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
#import <UIKit/UIKit.h>

/// key pressed event delegate
@protocol KeyGrabberDelegate <NSObject>
- (void)keyPressed:(int)key;
- (void)keyReleased:(int)key;
- (void)keyName:(NSString *)name pressed:(BOOL)pressed;
@end

/// a hidden view that grabs key events without showing the soft keyboard
///
/// uses UIPress events on iOS 13.4+ (keyPressed, keyReleased, keyName)
/// or
/// UIKeyInput for earlier iOS versions (keyPressed only)
///
/// non-printable key names from Tk https://tcl.tk/man/tcl8.6/TkCmd/keysyms.html
/// ex. "Return", "BackSpace", "Shift_L", etc
///
/// Usage:
///	inherit from the KeyGrabberDelegate and add a KeyGrabber as a subview:
///
///   KeyGrabberView *grabber = [[KeyGrabberView alloc] init];
///	  grabber.active = YES;
///	  grabber.delegate = self;
///	  [self.view addSubview:grabber];
///
@interface KeyGrabberView : UIView

/// enable key grabbing?
@property (assign, nonatomic) BOOL active;

/// set the delegate to receive events
@property (assign, nonatomic) id<KeyGrabberDelegate> delegate;

@end
