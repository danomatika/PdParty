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
#import <UIKit/UIKit.h>

// key pressed event delegate
@protocol KeyGrabberDelegate <NSObject>
@optional
- (void)keyPressed:(int)key;
@end

// a hidden view that grabs key events without showing the soft keyboard
// from https://github.com/scarnie/iCade-iOS/tree/master/iCadeTest/iCade
//
// sorry intl peeps, ASCII only
//
// Usage:
//	inherit from the KeyGrabberDelegate and add a KeyGrabber as a subview:
//
//    KeyGrabberView *grabber = [[KeyGrabberView alloc] init];
//	  grabber.active = YES;
//	  grabber.delegate = self;
//	  [self.view addSubview:grabber];
//
@interface KeyGrabberView : UIView<UIKeyInput>

// enable key grabbing?
@property (nonatomic, assign) BOOL active;

// set the delegate to receive events
@property (nonatomic, assign) id<KeyGrabberDelegate> delegate;

// or read the latest event value here
@property (nonatomic, assign) int key;

@end
