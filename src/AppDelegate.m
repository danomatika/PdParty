//
//  AppDelegate.m
//  PdParty
//
//  Created by Dan Wilcox on 1/27/13.
//  Copyright (c) 2013 danomatika. All rights reserved.
//

#import "AppDelegate.h"

#import "PdAudioController.h"
#import "PdParser.h"
#import "Log.h"

@interface AppDelegate () {}

@property (nonatomic, retain) PdAudioController *audioController;

- (void)setupPd;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	
	// init logger
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[[DDFileLogger alloc] init]];
	//ddLogLevel = [preferences logLevel];
	DDLogInfo(@"loglevel: %d", ddLogLevel);
	
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

#pragma mark Private

- (void)setupPd {
	// Configure a typical audio session with 2 output channels
	self.audioController = [[PdAudioController alloc] init];
	PdAudioStatus status = [self.audioController configurePlaybackWithSampleRate:44100
																  numberChannels:2
																	inputEnabled:NO
																   mixingEnabled:YES];
	if (status == PdAudioError) {
		DDLogError(@"Error: Could not configure PdAudioController");
	} else if (status == PdAudioPropertyChanged) {
		DDLogWarn(@"Warning: Some of the audio parameters were not accceptable");
	} else {
		DDLogInfo(@"Audio Configuration successful");
	}
	
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
	
			
	// load gui
	NSArray *atoms = [PdParser getAtomLines:[PdParser readPatch:[[NSBundle mainBundle] pathForResource:@"gui" ofType:@"pd"]]];
	[PdParser printAtoms:atoms];
	//gui.buildGui(atoms);

	//pd.openPatch("gui.pd");
}

#pragma mark - PdRecieverDelegate

// uncomment this to get print statements from pd
- (void)receivePrint:(NSString *)message {
	DDLogInfo(@"Pd Console: %@", message);
}

- (void)receiveBangFromSource:(NSString *)source {
	DDLogInfo(@"Pd Bang from %@", source);
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
	DDLogInfo(@"Pd Float from %@: %f", source, received);
//	if ([source isEqualToString:@"load-meter"]) {
//		self.viewController.loadPercentage = (int)received;
//	}
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	DDLogInfo(@"Pd Symbol from %@: %@", source, symbol);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	DDLogInfo(@"Pd List from %@", source);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	DDLogInfo(@"Pd Message to %@ from %@", message, source);
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
