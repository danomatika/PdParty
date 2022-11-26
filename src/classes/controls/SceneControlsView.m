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
#import "SceneControlsView.h"

#import "Log.h"
#import "Util.h"

@interface SceneControlsView () {
	UITapGestureRecognizer *sliderTapRecognizer;
	float prevSliderValue; // prev value on non-zero double-tap
}
@end

@implementation SceneControlsView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		self.delegate = self;
	}
    return self;
}

- (void)dealloc {
	if(self.sceneManager) {
		self.sceneManager.pureData.recordDelegate = nil;
	}
}

#pragma mark UI

- (UIBarButtonItem *)createLeftButton {
	return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pause"]
	                                        style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

- (UIBarButtonItem *)createRightButton {
	return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"record"]
	                                        style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

- (UISlider *)createSlider {
	UISlider *slider = [super createSlider];
	sliderTapRecognizer = [[UITapGestureRecognizer alloc] init];
	[sliderTapRecognizer addTarget:self action:@selector(sliderDoubleTapped:)];
	sliderTapRecognizer.numberOfTapsRequired = 2; // double-tap
	[slider addGestureRecognizer:sliderTapRecognizer];
	return slider;
}

- (void)updateControls {
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
	self.slider.value = self.sceneManager.pureData.micVolume;
}

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
	self.rightButton.tintColor = self.tintColor; // should reset to global color
}

- (void)rightButtonToStopRecord {
	self.rightButton.image = [UIImage imageNamed:@"record_filled"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"Stop";
	}
	self.rightButton.tintColor = [UIColor colorWithRed:0.945 green:0.231 blue:0.129 alpha:1.0]; // red/orange
}

#pragma mark ControlsViewDelegate

// play/pause
- (void)controlsViewLeftPressed:(ControlsView *)controlsView {
	self.sceneManager.pureData.audioEnabled = !self.sceneManager.pureData.audioEnabled;
	if(self.sceneManager.pureData.audioEnabled) {
		[self leftButtonToPause];
	}
	else {
		[self leftButtonToPlay];
	}
}

// recording
- (void)controlsViewRightPressed:(ControlsView *)controlsView {
	if(!self.sceneManager.pureData.isRecording) {
		[self.sceneManager.pureData startedRecordingToRecordDir:self.sceneManager.scene.name withTimestamp:YES];
		[self rightButtonToStopRecord];
	}
	else {
		[self.sceneManager.pureData stopRecording];
		[self rightButtonToRecord];
	}
}

- (void)controlsView:(ControlsView *)controlsView sliderStartedTracking:(float)value {
	// noop
}

- (void)controlsView:(ControlsView *)controlsView sliderStoppedTracking:(float)value {
	// noop
}

// mic volume
- (void)controlsView:(ControlsView *)controlsView sliderValueChanged:(float)value {
	self.sceneManager.pureData.micVolume = self.slider.value;
}

#pragma mark PdRecordEventDelegate

// outside events need to update the gui

- (void)remoteRecordingStarted {
	[self rightButtonToStopRecord];
}

- (void)remoteRecordingFinished {
	[self rightButtonToRecord];
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

- (void)setLightBackground:(BOOL)lightBackground {
	[super setLightBackground:lightBackground];
	[self levelIconTo:@"microphone"]; // reload
}

#pragma mark Private

// double-tap microphone image to toggle mic input value
- (void)sliderDoubleTapped:(id)sender {
	CGPoint location = [sliderTapRecognizer locationInView:self.slider];
	CGRect rect = [self.slider minimumValueImageRectForBounds:self.slider.bounds];
	if(CGRectContainsPoint(rect, location)) {
		if(self.slider.value > 0) {
			prevSliderValue = self.slider.value;
			self.slider.value = 0;
		}
		else {
			self.slider.value = (prevSliderValue > 0 ? prevSliderValue : 0.25);
		}
	}
}

- (void)levelIconTo:(NSString *)name {
	if(self.lightBackground) {
		self.slider.minimumValueImage = [UIImage imageNamed:name];
	}
	else {
		self.slider.minimumValueImage = [Util image:[UIImage imageNamed:name] withTint:UIColor.whiteColor];
	}
}

@end
