//
//  AppDelegate.m
//  PdParty
//
//  Created by Dan Wilcox on 1/11/13.
//  Copyright (c) 2013 Dan Wilcox. All rights reserved.
//

#import "AppDelegate.h"

#import "PdAudioController.h"

@interface AppDelegate () {

	NSMutableString * printMsg; // for appending print messages
}

@property (nonatomic, retain) PdAudioController *audioController;

- (void)setupPd;

@end

@implementation AppDelegate

@synthesize window = window_;
//@synthesize viewController = viewController_;
@synthesize audioController = audioController_;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	    splitViewController.delegate = (id)navigationController.topViewController;
	}
	
	[self setupPd];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setupPd {
	// Configure a typical audio session with 2 output channels
	self.audioController = [[PdAudioController alloc] init];
	PdAudioStatus status = [self.audioController configurePlaybackWithSampleRate:44100
																  numberChannels:2
																	inputEnabled:NO
																   mixingEnabled:YES];
	if (status == PdAudioError) {
		NSLog(@"Error! Could not configure PdAudioController");
	} else if (status == PdAudioPropertyChanged) {
		NSLog(@"Warning: some of the audio parameters were not accceptable.");
	} else {
		NSLog(@"Audio Configuration successful.");
	}
	
	// setup print msg
	printMsg = [[NSMutableString alloc] init];
	
	// log actually settings
	[self.audioController print];

	// set AppDelegate as PdRecieverDelegate to recieve messages from pd
    [PdBase setDelegate:self];

	// recieve all [send load-meter] messages from pd
	[PdBase subscribe:@"toOF"];

	// open one instance of the load-meter patch and forget about it
	[PdBase openFile:@"test.pd" path:[[NSBundle mainBundle] bundlePath]];
	
	// turn on dsp
	//[PdBase computeAudio:true];
	[self setPlaying:YES];
	
	[PdBase sendSymbol:@"test" toReceiver:@"fromOF"];
}

#pragma mark - PdRecieverDelegate

// uncomment this to get print statements from pd
- (void)receivePrint:(NSString *)message {
	
	// append print messages into a single line
	// look for the endline to know we're done appending the current message
    if(message.length > 0 && [message characterAtIndex:message.length-1] == '\n') {

        // build the message, remove the endl
        if(message.length > 1) {
			[printMsg appendString:[message substringToIndex:message.length-1]];
        }

		// got the line, so print
		NSLog(@"Pd Console: %@", printMsg);

        [printMsg setString:@""];
        return;
    }

    // build the message
    [printMsg appendString:message];
}

- (void)receiveBangFromSource:(NSString *)source {
	NSLog(@"Pd Bang from %@", source);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	NSLog(@"Pd Float from %@: %f", source, received);
//	if ([source isEqualToString:@"load-meter"]) {
//		self.viewController.loadPercentage = (int)received;
//	}
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	NSLog(@"Pd Symbol from %@: %@", source, symbol);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	NSLog(@"Pd List from %@", source);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	NSLog(@"Pd Message to %@ from %@", message, source);
}

#pragma mark - Accessors

- (BOOL)isPlaying {
    return playing_;
}

- (void)setPlaying:(BOOL)newState {
    if( newState == playing_ )
		return;

	playing_ = newState;
	self.audioController.active = playing_;
}

@end
