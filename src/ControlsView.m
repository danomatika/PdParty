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
#import "ControlsView.h"

#import "Log.h"
#import "AppDelegate.h"

@interface ControlsView () {
	NSLayoutConstraint *heightConstraint;
}
@end

@implementation ControlsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {

		int defaultHeight = 192, toolBarHeight = 88, spaceWidth = 84;
		if(![Util isDeviceATablet]) {
			defaultHeight = 96;
			toolBarHeight = 44;
			spaceWidth = 42;
		}

		self.backgroundColor = [UIColor blackColor];

		self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), toolBarHeight)];
		self.toolbar.barStyle = UIBarStyleBlack;
		
		self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
		self.rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Record" style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
	
		UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		leftSpace.width = spaceWidth;
		UIBarButtonItem *middleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(controlChanged:)];
		UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		rightSpace.width = spaceWidth;
	
		[self.toolbar setItems:[NSArray arrayWithObjects:leftSpace, self.leftButton, middleSpace, self.rightButton, rightSpace, nil]];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.toolbar];
		
		self.levelSlider = [[UISlider alloc] init];
		[self.levelSlider addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
		self.levelSlider.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.levelSlider];
		
		// auto layout constraints
		heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
									toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:defaultHeight];
		[self addConstraint:heightConstraint];
		
		[self addConstraints:[NSArray arrayWithObjects:
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
										    toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:toolBarHeight],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0], nil]];
		
		[self addConstraints:[NSArray arrayWithObjects:
			[NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:spaceWidth],
			[NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-spaceWidth],
			[NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:toolBarHeight/2],
											 nil]];
								
		[self setNeedsUpdateConstraints];
	}
    return self;
}

- (void)dealloc {
	if(self.sceneManager) {
		self.sceneManager.pureData.delegate = nil;
	}
}

- (void)controlChanged:(id)sender {

	if(sender == self.leftButton) {
		//DDLogVerbose(@"ControlsView: left button pressed");
		if(self.sceneManager.scene.type == SceneTypeRj) {
			self.sceneManager.pureData.audioEnabled = !self.sceneManager.pureData.audioEnabled;
			if(self.sceneManager.pureData.audioEnabled) {
				[self.leftButton setTitle:@"Pause"];
			}
			else {
				[self.leftButton setTitle:@"Play"];
			}
		}
		else if(self.sceneManager.scene.type == SceneTypeRecording) {						
			if(self.sceneManager.pureData.audioEnabled) {
				
				// restart playback if stopped
				if(!self.sceneManager.pureData.isPlayingback) {
					[(RecordingScene *)self.sceneManager.scene restartPlayback];
					[self.leftButton setTitle:@"Pause"];
				}
				else { // pause
					self.sceneManager.pureData.audioEnabled = NO;
					[self.leftButton setTitle:@"Play"];
				}
			}
			else {
				self.sceneManager.pureData.audioEnabled = YES;
				[(RecordingScene *)self.sceneManager.scene restartPlayback];
				[self.leftButton setTitle:@"Pause"];
			}
		}
	}
	else if(sender == self.rightButton) {
		//DDLogVerbose(@"ControlsView: right button pressed");
		if(self.sceneManager.scene.type == SceneTypeRj) {
			if(!self.sceneManager.pureData.isRecording) {
				
				NSString *recordDir = [[Util documentsPath] stringByAppendingPathComponent:@"recordings"];
				if(![[NSFileManager defaultManager] fileExistsAtPath:recordDir]) {
					DDLogVerbose(@"ControlsView: recordings dir not found, creating %@", recordDir);
					NSError *error;
					if(![[NSFileManager defaultManager] createDirectoryAtPath:recordDir withIntermediateDirectories:NO attributes:nil error:&error]) {
						DDLogError(@"ControlsView: couldn't create %@, error: %@", recordDir, error.localizedDescription);
						return;
					}
				}
				
				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat:@"yy-MM-dd_hhmmss"];
				NSString *date = [formatter stringFromDate:[NSDate date]];
				[self.sceneManager.pureData startRecordingTo:[recordDir stringByAppendingPathComponent:[self.sceneManager.scene.name stringByAppendingFormat:@"_%@.wav", date]]];
				[self.rightButton setTitle:@"Stop"];
			}
			else {
				[self.sceneManager.pureData stopRecording];
				[self.rightButton setTitle:@"Record"];
			}
		}
		else if(self.sceneManager.scene.type == SceneTypeRecording) {
			self.sceneManager.pureData.looping = !self.sceneManager.pureData.isLooping;
			if(self.sceneManager.pureData.isLooping) {
				[self.rightButton setTitle:@"No Loop"];
			}
			else {
				[self.rightButton setTitle:@"Loop"];
			}
		}
	}
	else if(sender == self.levelSlider) {
		//DDLogVerbose(@"ControlsView: level slider changed: %f", self.levelSlider.value);
		if(self.sceneManager.scene.type == SceneTypeRj) {
			self.sceneManager.pureData.micVolume = self.levelSlider.value;
		}
		else if(self.sceneManager.scene.type == SceneTypeRecording) {
			self.sceneManager.pureData.volume = self.levelSlider.value;
		}
	}
}

- (void)updateControls {
	
	if(self.sceneManager.scene.type == SceneTypeRj) {
	
		if(self.sceneManager.pureData.audioEnabled) {
			[self.leftButton setTitle:@"Pause"];
		}
		else {
			[self.leftButton setTitle:@"Play"];
		}
	
		if(self.sceneManager.pureData.isRecording) {
			[self.rightButton setTitle:@"Stop"];
		}
		else {
			[self.rightButton setTitle:@"Record"];
		}
		
		self.levelSlider.value = self.sceneManager.pureData.micVolume;
	}
	else if(self.sceneManager.scene.type == SceneTypeRecording) {
	
		if(self.sceneManager.pureData.audioEnabled && self.sceneManager.pureData.isPlayingback) {
			[self.leftButton setTitle:@"Pause"];
		}
		else {
			[self.leftButton setTitle:@"Play"];
		}
	
		// use record as loop button for recording playback
		if(self.sceneManager.pureData.isLooping) {
			[self.rightButton setTitle:@"No Loop"];
		}
		else {
			[self.rightButton setTitle:@"Loop"];
		}
		
		// use slider as recording playback volume slider
		self.levelSlider.value = self.sceneManager.pureData.volume;
	}
}

#pragma mark Overridden Getters / Setters

- (void)setSceneManager:(SceneManager *)sceneManager {
	if(sceneManager == _sceneManager) {
		return;
	}
	if(self.sceneManager) {
		self.sceneManager.pureData.delegate = nil;
	}
	_sceneManager = sceneManager;
	self.sceneManager.pureData.delegate = self;
}

- (void)setHeight:(float)height {
	heightConstraint.constant = height;
}

- (float)height {
	return heightConstraint.constant;
}

#pragma mark PdPlaybackDelegate

- (void)playbackFinished {
	[self.leftButton setTitle:@"Play"];
}

@end
