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
#import "App.h"

#import "AppDelegate.h"

@implementation App

#pragma mark Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if(motion == UIEventSubtypeMotionShake) {
		[NSNotificationCenter.defaultCenter postNotificationName:PdPartyMotionShakeEndedNotification
														  object:self];
	}
}

@end
