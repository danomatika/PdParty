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

@interface ControlsView () {
	NSLayoutConstraint *heightConstraint;
	NSLayoutConstraint *toolbarHeightConstraint;
	NSLayoutConstraint *sliderLeadingConstraint;
	NSLayoutConstraint *sliderTrailingConstraint;
	NSLayoutConstraint *sliderCenterYConstraint;
}
@property (readwrite, nonatomic) float defaultHeight;
@property (readwrite, nonatomic) float defaultSpacing;
@property (readwrite, nonatomic) float defaultToolbarHeight;
@end

@implementation ControlsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {

		self.defaultHeight = 192;
		self.defaultSpacing = 84;
		self.defaultToolbarHeight = 88;
		if(![Util isDeviceATablet]) {
			self.defaultHeight = 96;
			self.defaultSpacing = 42;
			self.defaultToolbarHeight = 44;
		}

		self.backgroundColor = [UIColor blackColor];

		self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), self.toolbarHeight)];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		self.toolbar.barStyle = UIBarStyleBlack;
		
//		self.leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(controlChanged:)];
		
		self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
		self.rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Record" style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
	
		UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		leftSpace.width = self.defaultSpacing;
		UIBarButtonItem *middleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(controlChanged:)];
		UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		rightSpace.width = self.defaultSpacing;
	
		[self.toolbar setItems:[NSArray arrayWithObjects:leftSpace, self.leftButton, middleSpace, self.rightButton, rightSpace, nil]];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.toolbar];
		
		self.levelSlider = [[UISlider alloc] init];
		[self.levelSlider addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
		self.levelSlider.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.levelSlider];
		
		// auto layout constraints
		heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
									toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.defaultHeight];
		
		toolbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
										    toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.defaultToolbarHeight],
		
		sliderLeadingConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:self.defaultSpacing],
		sliderTrailingConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-self.defaultSpacing],
		sliderCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:self.defaultToolbarHeight/2],
		
		[self addConstraints:[NSArray arrayWithObjects: heightConstraint, toolbarHeightConstraint,
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
			sliderLeadingConstraint, sliderTrailingConstraint, sliderCenterYConstraint, nil]];
								
		[self setNeedsUpdateConstraints];
	}
    return self;
}

- (void)dealloc {
	if(self.sceneManager) {
		self.sceneManager.pureData.recordDelegate = nil;
	}
}

#pragma mark UI

- (void)controlChanged:(id)sender {

	if(sender == self.leftButton) {
		//DDLogVerbose(@"ControlsView: left button pressed");
		if(self.sceneManager.scene.type == SceneTypeRecording) {						
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
		else {
			self.sceneManager.pureData.audioEnabled = !self.sceneManager.pureData.audioEnabled;
			if(self.sceneManager.pureData.audioEnabled) {
				[self.leftButton setTitle:@"Pause"];
			}
			else {
				[self.leftButton setTitle:@"Play"];
			}
		}
	}
	else if(sender == self.rightButton) {
		//DDLogVerbose(@"ControlsView: right button pressed");
		if(self.sceneManager.scene.type == SceneTypeRecording) {
			self.sceneManager.pureData.looping = !self.sceneManager.pureData.isLooping;
			if(self.sceneManager.pureData.isLooping) {
				[self.rightButton setTitle:@"No Loop"];
			}
			else {
				[self.rightButton setTitle:@"Loop"];
			}
		}
		else {
			if(!self.sceneManager.pureData.isRecording) {
				[self.sceneManager.pureData startedRecordingToRecordDir:self.sceneManager.scene.name withTimestamp:YES];
				[self.rightButton setTitle:@"Stop"];
			}
			else {
				[self.sceneManager.pureData stopRecording];
				[self.rightButton setTitle:@"Record"];
			}
		}
	}
	else if(sender == self.levelSlider) {
		//DDLogVerbose(@"ControlsView: level slider changed: %f", self.levelSlider.value);
		if(self.sceneManager.scene.type == SceneTypeRecording) {
			self.sceneManager.pureData.volume = self.levelSlider.value;
		}
		else {
			self.sceneManager.pureData.micVolume = self.levelSlider.value;
		}
	}
}

- (void)updateControls {
	
	if(self.sceneManager.scene.type == SceneTypeRecording) {
	
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
	else {
		
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
}

#pragma mark Sizing

- (void)halfDefaultSize {
	self.height = 96; // not quite half of default
	self.spacing = self.defaultSpacing/2;
	self.toolbarHeight = self.defaultToolbarHeight/2;
	[self setNeedsUpdateConstraints];
}

- (void)defaultSize {
	self.height = self.defaultHeight;
	self.spacing = self.defaultSpacing;
	self.toolbarHeight = self.defaultToolbarHeight;
	[self setNeedsUpdateConstraints];
}

#pragma mark Overridden Getters / Setters

- (void)setSceneManager:(SceneManager *)sceneManager {
	if(sceneManager == _sceneManager) {
		return;
	}
	if(self.sceneManager) {
		self.sceneManager.pureData.recordDelegate = nil;
	}
	_sceneManager = sceneManager;
	self.sceneManager.pureData.recordDelegate = self;
}

- (void)setHeight:(float)height {
	heightConstraint.constant = height;
}

- (float)height {
	return heightConstraint.constant;
}

- (void)setSpacing:(float)spacing {

	sliderLeadingConstraint.constant = spacing;
	sliderTrailingConstraint.constant = -spacing;
	
	// assume tool bar fixed width spaces are first and last
	[[self.toolbar.items objectAtIndex:0] setWidth:spacing];
	[[self.toolbar.items objectAtIndex:self.toolbar.items.count-1] setWidth:spacing];
}

- (float)spacing {
	return sliderLeadingConstraint.constant;
}

- (void)setToolbarHeight:(float)toolbarHeight {
	toolbarHeightConstraint.constant = toolbarHeight;
	sliderCenterYConstraint.constant = toolbarHeight/2;
}

- (float)toolbarHeight {
	return toolbarHeightConstraint.constant;
}

#pragma mark PdRecordEventDelegate

// outside events need to update the gui

- (void)remoteRecordingStarted {
	[self.rightButton setTitle:@"Stop"];
}

- (void)remoteRecordingFinished {
	[self.rightButton setTitle:@"Record"];
}

- (void)playbackFinished {
	[self.leftButton setTitle:@"Play"];
}

@end
