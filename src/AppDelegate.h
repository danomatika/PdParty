//
//  AppDelegate.h
//  PdParty
//
//  Created by Dan Wilcox on 1/27/13.
//  Copyright (c) 2013 danomatika. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PdBase.h"
#import "PdDispatcher.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, PdListener>

@property (strong, nonatomic) UIWindow *window;

@property (strong) PdDispatcher *dispatcher;

@property (getter=isPlaying) BOOL playing; // a globally accesible flag to start or stop audio

@end
