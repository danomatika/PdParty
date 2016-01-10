/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

/// modal console log text view, uses Log textViewLogger
@interface ConsoleViewController : UIViewController

/// text view to display current log lines
@property (strong, nonatomic) UITextView *textView;

@end
