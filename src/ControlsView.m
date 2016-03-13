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
#import "Util.h"

@interface ControlsView () {
	NSString *currentLevelIcon;
	NSLayoutConstraint *heightConstraint;
	NSLayoutConstraint *toolbarHeightConstraint;
	NSLayoutConstraint *sliderLeadingConstraint;
	NSLayoutConstraint *sliderTrailingConstraint;
	NSLayoutConstraint *sliderCenterYConstraint;
}
@property (readwrite, nonatomic) float defaultHeight;
@property (readwrite, nonatomic) float defaultSpacing;
@property (readwrite, nonatomic) float defaultToolbarHeight;
@property (nonatomic) BOOL showsMicIcon;
@end

@implementation ControlsView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		
		self.defaultHeight = [ControlsView baseHeight];
		self.defaultSpacing = [ControlsView baseSpacing];
		self.defaultToolbarHeight = [ControlsView baseToolbarHeight];
		
		self.backgroundColor = [UIColor blackColor];

		self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), self.toolbarHeight)];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		self.toolbar.barStyle = UIBarStyleBlack;
		self.toolbar.translucent = NO;
		
		self.leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pause"] style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
		self.rightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"record"] style:UIBarButtonItemStylePlain target:self action:@selector(controlChanged:)];
	
		UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		leftSpace.width = self.defaultSpacing;
		UIBarButtonItem *middleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(controlChanged:)];
		UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(controlChanged:)];
		rightSpace.width = self.defaultSpacing;
	
		[self.toolbar setItems:[NSArray arrayWithObjects:leftSpace, self.leftButton, middleSpace, self.rightButton, rightSpace, nil]];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.toolbar];
		
		self.levelSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), self.defaultHeight)];
		[self.levelSlider addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
		self.levelSlider.translatesAutoresizingMaskIntoConstraints = NO;
		self.levelSlider.minimumValue = 0.0;
		self.levelSlider.maximumValue = 1.0;
		self.showsMicIcon = YES;
		
		[self addSubview:self.levelSlider];
		
		self.lightBackground = false;
		
		// auto layout constraints
		
		// keep overall height from getting too small
		heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual
									toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.defaultHeight];
		
		// lock toolbar height to given size
		toolbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
										    toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.defaultToolbarHeight],
		
		// keep slider centered within space under toolbar
		sliderLeadingConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:self.defaultSpacing],
		sliderTrailingConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-self.defaultSpacing],
		sliderCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.levelSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:self.defaultToolbarHeight/2],
		
		[self addConstraints:[NSArray arrayWithObjects: heightConstraint, toolbarHeightConstraint,
			
			// keep toolbar at top with full width
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
										    toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
			
			// slider
			sliderLeadingConstraint, sliderTrailingConstraint, sliderCenterYConstraint, nil]];
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
		if([self.sceneManager.scene.type isEqualToString:@"RecordingScene"]) {
			if(self.sceneManager.pureData.audioEnabled) {
				
				// restart playback if stopped
				if(!self.sceneManager.pureData.isPlayingback) {
					[(RecordingScene *)self.sceneManager.scene restartPlayback];
					[self leftButtonToPause];
				}
				else { // pause
					self.sceneManager.pureData.audioEnabled = NO;
					[self leftButtonToPlay];
				}
			}
			else {
				self.sceneManager.pureData.audioEnabled = YES;
				[(RecordingScene *)self.sceneManager.scene restartPlayback];
				[self leftButtonToPause];
			}
		}
		else {
			self.sceneManager.pureData.audioEnabled = !self.sceneManager.pureData.audioEnabled;
			if(self.sceneManager.pureData.audioEnabled) {
				[self leftButtonToPause];
			}
			else {
				[self leftButtonToPlay];
			}
		}
	}
	else if(sender == self.rightButton) {
		//DDLogVerbose(@"ControlsView: right button pressed");
		if([self.sceneManager.scene.type isEqualToString:@"RecordingScene"]) {
			self.sceneManager.pureData.looping = !self.sceneManager.pureData.isLooping;
			if(self.sceneManager.pureData.isLooping) {
				[self rightButtonToStopLoop];
			}
			else {
				[self rightButtonToLoop];
			}
		}
		else {
			if(!self.sceneManager.pureData.isRecording) {
				[self.sceneManager.pureData startedRecordingToRecordDir:self.sceneManager.scene.name withTimestamp:YES];
				[self rightButtonToStopRecord];
			}
			else {
				[self.sceneManager.pureData stopRecording];
				[self rightButtonToRecord];
			}
		}
	}
	else if(sender == self.levelSlider) {
		//DDLogVerbose(@"ControlsView: level slider changed: %f", self.levelSlider.value);
		if([self.sceneManager.scene.type isEqualToString:@"RecordingScene"]) {
			self.sceneManager.pureData.volume = self.levelSlider.value;
		}
		else {
			self.sceneManager.pureData.micVolume = self.levelSlider.value;
		}
	}
}

- (void)updateControls {
	if([self.sceneManager.scene.type isEqualToString:@"RecordingScene"]) {
	
		if(self.sceneManager.pureData.audioEnabled && self.sceneManager.pureData.isPlayingback) {
			[self leftButtonToPause];
		}
		else {
			[self leftButtonToPlay];
		}
	
		// use record as loop button for recording playback
		if(self.sceneManager.pureData.isLooping) {
			[self rightButtonToStopLoop];
		}
		else {
			[self rightButtonToLoop];
		}
		
		// use slider as recording playback volume slider
		self.levelSlider.value = self.sceneManager.pureData.volume;
		self.showsMicIcon = NO;
	}
	else {
		
		if(self.sceneManager.pureData.audioEnabled) {
			[self leftButtonToPause];
		}
		else {
			[self leftButtonToPlay];
		}
		
		self.rightButton.enabled = self.sceneManager.scene.records;
		if(self.sceneManager.pureData.isRecording) {
			[self rightButtonToStopRecord];
		}
		else {
			[self rightButtonToRecord];
		}
		
		self.levelSlider.value = self.sceneManager.pureData.micVolume;
		self.showsMicIcon = YES;
	}
}

#pragma mark Sizing

+ (float)baseWidth {
	if([Util isDeviceATablet]) {
		return 320;
	}
	else { // smaller popups on iPhone
		return ([Util deviceOSVersion] >= 8.0) ? 300 : 280;
	}
}

+ (float)baseHeight {
	return [Util isDeviceATablet] ? 192 : 96;
}

+ (float)baseSpacing {
	return [Util isDeviceATablet] ? 84 : 42;
}

+ (float)baseToolbarHeight {
	return [Util isDeviceATablet] ? 88 : 44;
}

- (void)halfSize {
	self.height = 96;
	self.spacing = self.defaultSpacing/2;
	self.toolbarHeight = self.defaultToolbarHeight/2;
	[self setNeedsUpdateConstraints];
}

- (void)defaultSize {
	self.height = self.defaultHeight;
	self.spacing = [Util isDeviceATablet] ? self.defaultSpacing*2 : self.defaultSpacing;
	self.toolbarHeight = self.defaultToolbarHeight;
	[self setNeedsUpdateConstraints];
}

#pragma Layout

- (void)alignToSuperview {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
}

- (void)alignToSuperviewBottom {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]|"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
}

- (void)alignToSuperviewTop {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]"
																		   options:0
																		   metrics:nil
																			 views:@{@"view" : self}]];
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
	[[self.toolbar.items firstObject] setWidth:spacing];
	[[self.toolbar.items lastObject] setWidth:spacing];
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

- (void)setLightBackground:(BOOL)lightBackground {
	if(_lightBackground == lightBackground) {
		return;
	}
	_lightBackground = lightBackground;
	if(lightBackground) {
		self.backgroundColor = [UIColor whiteColor];
		self.toolbar.barTintColor = [UIColor whiteColor];
	}
	else {
		self.backgroundColor = [UIColor blackColor];
		self.toolbar.barTintColor = [UIColor blackColor];
	}
	[self levelIconTo:currentLevelIcon]; // reload
}

- (void)setShowsMicIcon:(BOOL)showsMicIcon {
	if(_showsMicIcon == showsMicIcon) {
		return;
	}
	_showsMicIcon = showsMicIcon;
	if(_showsMicIcon) {
		[self levelIconTo:@"microphone"];
	}
	else {
		[self levelIconTo:@"speaker"];
	}
}

#pragma mark PdRecordEventDelegate

// outside events need to update the gui

- (void)remoteRecordingStarted {
	[self rightButtonToStopRecord];
}

- (void)remoteRecordingFinished {
	[self rightButtonToRecord];
}

- (void)playbackFinished {
	[self leftButtonToPlay];
}

#pragma mark Private

- (void)leftButtonToPlay {
	self.leftButton.image = [UIImage imageNamed:@"play"];
	if(!self.leftButton.image) {
		self.leftButton.title = @"Play";
	}
}

- (void)leftButtonToPause {
	self.leftButton.image = [UIImage imageNamed:@"pause"];
	if(!self.leftButton.image) {
		self.leftButton.title = @"Pause";
	}
}

- (void)rightButtonToRecord {
	self.rightButton.image = [UIImage imageNamed:@"record"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"Record";
	}
	if([self respondsToSelector:@selector(setTintColor:)]) {
		self.rightButton.tintColor = [self tintColor]; // should reset to global color
	}
	else { // iOS 6
		self.rightButton.tintColor = [UIColor whiteColor];
	}
}

- (void)rightButtonToStopRecord {
	self.rightButton.image = [UIImage imageNamed:@"record_filled"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"Stop";
	}
	self.rightButton.tintColor = [UIColor colorWithRed:0.945 green:0.231 blue:0.129 alpha:1.0]; // red/orange
}

- (void)rightButtonToLoop {
	self.rightButton.image = [UIImage imageNamed:@"loop"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"Loop";
	}
	self.rightButton.tintColor = [UIColor grayColor];
}

- (void)rightButtonToStopLoop {
	self.rightButton.image = [UIImage imageNamed:@"loop"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"No Loop";
	}
	self.rightButton.tintColor = [self tintColor]; // should reset to global color
}

- (void)levelIconTo:(NSString *)name {
	if(self.lightBackground) {
		self.levelSlider.minimumValueImage = [UIImage imageNamed:name];
	}
	else {
		self.levelSlider.minimumValueImage = [Util image:[UIImage imageNamed:name] withTint:[UIColor whiteColor]];
	}
	currentLevelIcon = name;
}

@end
