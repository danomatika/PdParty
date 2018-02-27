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
#import "ControlsView.h"
#import <CoreMedia/CMTime.h>

/// audio file player onscreen controls
@interface PlayerControlsView : ControlsView {
	NSLayoutConstraint *timeElapsedLabelConstraint;
	NSLayoutConstraint *timeRemainLabelConstraint;
}

/// time elapsed on left side of slider, default width for "HH:MM:SS"
@property (strong, nonatomic) UILabel *timeElapsedLabel;

/// time remaining on right side of slider, default width for "HH:MM:SS"
@property (strong, nonatomic) UILabel *timeRemainLabel;

/// clear time elapsed and reset time remaining to duration,
/// assumes valid time and only shows hours if duration is long enough
- (void)resetForDuration:(const CMTime)duration;

/// set elapsed time and tiem remaing by sbtracting from duration,
/// assumes valid times and only shows hours if duration is long enough
- (void)setElapsedTime:(const CMTime)time forDuration:(const CMTime)duration;

/// set the current slider positon based on a given time and duration
- (void)setCurrentTime:(const CMTime)time forDuration:(const CMTime)duration;

#pragma mark UI

/// set left button to play icon
- (void)leftButtonToPlay;

/// set left button to pause icon
- (void)leftButtonToPause;

/// set right button to loop icon
- (void)rightButtonToLoop;

/// set right button to stop loop icon
- (void)rightButtonToStopLoop;

@end
