//
//  AppDelegate.h
//  PdParty
//
//  Created by Dan Wilcox on 1/11/13.
//  Copyright (c) 2013 Dan Wilcox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdBase.h"

@interface AppDelegate : NSObject <UIApplicationDelegate, PdReceiverDelegate> {
	BOOL playing_;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, getter=isPlaying) BOOL playing; // a globally accesible flag to start or stop audio

@end
