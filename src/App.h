/*
* Copyright (c) 2020 Dan Wilcox <danomatika@gmail.com>
*
* BSD Simplified License.
* For information on usage and redistribution, and for a DISCLAIMER OF ALL
* WARRANTIES, see the file, "LICENSE.txt," in this distribution.
*
* See https://github.com/danomatika/PdParty for documentation
*
*/
#import <UIKit/UIKit.h>

/// forward global shake events as notifications so they can be handled
/// no matter which view is the firstResponder
@interface App : UIApplication

@end
