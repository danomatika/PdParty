/*
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PlayerControlsView.h"

#import "Log.h"
#import "Util.h"

@interface PlayerControlsView () {
	BOOL looping;
}
@end

@implementation PlayerControlsView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		looping = NO;
		int fontSize = (Util.isDeviceATablet ? 17 : 12);

		self.timeElapsedLabel = [[UILabel alloc] init];
		self.timeElapsedLabel.text = @"00:00:00";
		self.timeElapsedLabel.textAlignment = NSTextAlignmentRight;
		self.timeElapsedLabel.font = [UIFont fontWithName:@"Menlo" size:12];
		self.timeElapsedLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.timeElapsedLabel sizeToFit];
		[self addSubview:self.timeElapsedLabel];

		self.timeRemainLabel = [[UILabel alloc] init];
		self.timeRemainLabel.text = @"00:00:00";
		self.timeRemainLabel.textAlignment = NSTextAlignmentLeft;
		self.timeRemainLabel.font = [UIFont fontWithName:@"Menlo" size:12];
		self.timeRemainLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.timeRemainLabel sizeToFit];
		[self addSubview:self.timeRemainLabel];

		// add labels in line with slider
		[self removeConstraints:@[sliderLeadingConstraint, sliderTrailingConstraint]];
		sliderLeadingConstraint =
			[NSLayoutConstraint constraintWithItem:self.timeElapsedLabel
			                             attribute:NSLayoutAttributeLeading
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeLeading
			                            multiplier:1.0
			                              constant:self.defaultSpacing/2];
		timeElapsedLabelConstraint =
			[NSLayoutConstraint constraintWithItem:self.timeElapsedLabel
			                             attribute:NSLayoutAttributeLeading
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self.slider
			                             attribute:NSLayoutAttributeLeading
			                            multiplier:1.0
			                              constant:-CGRectGetWidth(self.timeElapsedLabel.bounds)*1.1];
		timeRemainLabelConstraint =
			[NSLayoutConstraint constraintWithItem:self.timeRemainLabel
			                             attribute:NSLayoutAttributeTrailing
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self.slider
			                             attribute:NSLayoutAttributeTrailing
			                            multiplier:1.0
			                              constant:CGRectGetWidth(self.timeRemainLabel.bounds)*1.1];
		sliderTrailingConstraint =
			[NSLayoutConstraint constraintWithItem:self.timeRemainLabel
			                             attribute:NSLayoutAttributeTrailing
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeTrailing
			                            multiplier:1.0
			                              constant:-self.defaultSpacing/2];
		[self addConstraints:@[timeElapsedLabelConstraint, timeRemainLabelConstraint,
							   sliderLeadingConstraint, sliderTrailingConstraint,
			[NSLayoutConstraint constraintWithItem:self.timeElapsedLabel
			                             attribute:NSLayoutAttributeCenterY
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeCenterY
			                            multiplier:1.0
			                              constant:self.defaultToolbarHeight/2],
			[NSLayoutConstraint constraintWithItem:self.timeRemainLabel
			                             attribute:NSLayoutAttributeCenterY
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeCenterY
			                            multiplier:1.0
			                              constant:self.defaultToolbarHeight/2]
		]];
		[self setNeedsUpdateConstraints];

		// colors
		self.lightBackground = NO;
	}
    return self;
}

- (UIBarButtonItem *)createLeftButton {
	return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"play"]
	                                        style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

- (UIBarButtonItem *)createRightButton {
	return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"loop"]
	                                        style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

// avoid showing hours time component unless duration is long enough
- (void)resetForDuration:(const CMTime)duration {
	int total = (CMTimeCompare(duration, kCMTimeIndefinite) == 0 ? 0 : CMTimeGetSeconds(duration));
	BOOL showHours = (BOOL)(total / 360);
	self.timeElapsedLabel.text =
		[NSString stringWithFormat:@"%@00:00", (showHours ? @"00:" : @"")];
	self.timeRemainLabel.text =
		[NSString stringWithFormat:@"%@%02d:%02d",
			(showHours ? [NSString stringWithFormat:@"%02d:", total / 360] : @""),
			(total / 60) % 60, // min
			total % 60]; // sec
}

// avoid showing hours time component unless duration is long enough
- (void)setElapsedTime:(const CMTime)time forDuration:(const CMTime)duration {
	int elapsed = CMTimeGetSeconds(time);
	int total = CMTimeGetSeconds(duration);
	int remain = total - elapsed;
	BOOL showHours = (BOOL)(total / 360);
	self.timeElapsedLabel.text =
		[NSString stringWithFormat:@"%@%02d:%02d",
			(showHours ? [NSString stringWithFormat:@"%02d:", elapsed / 360] : @""),
			(elapsed / 60) % 60, // min
			elapsed % 60]; // sec
	self.timeRemainLabel.text =
		[NSString stringWithFormat:@"%@%02d:%02d",
			(showHours ? [NSString stringWithFormat:@"%02d:", remain / 360] : @""),
			(remain / 60) % 60, // min
			remain % 60]; // sec
}

- (void)setCurrentTime:(const CMTime)time forDuration:(const CMTime)duration {
	int elapsed = CMTimeGetSeconds(time);
	int total = CMTimeGetSeconds(duration);
	if(total < 0) {
		self.slider.value = 0.0;
	}
	else {
		self.slider.value = (float)elapsed / (float)total;
	}
}

#pragma mark UI

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

- (void)rightButtonToLoop {
	self.rightButton.image = [UIImage imageNamed:@"loop"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"Loop";
	}
	self.rightButton.tintColor = UIColor.grayColor;
}

- (void)rightButtonToStopLoop {
	self.rightButton.image = [UIImage imageNamed:@"loop"];
	if(!self.rightButton.image) {
		self.rightButton.title = @"No Loop";
	}
	self.rightButton.tintColor = self.tintColor; // should reset to global color
}

#pragma mark Overridden Getters / Setters

- (void)setLightBackground:(BOOL)lightBackground {
	[super setLightBackground:lightBackground];
	UIColor *textColor;
	if(@available(iOS 13.0, *)) {
		textColor = lightBackground ? UIColor.labelColor : UIColor.whiteColor;
	}
	else {
		textColor = lightBackground ? UIColor.blackColor : UIColor.whiteColor;
	}
	self.timeElapsedLabel.textColor = textColor;
	self.timeRemainLabel.textColor = textColor;
}

@end
