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

#import "SceneManager.h"

/// RjDj-inspired onscreen controls for PureData scenes
@interface SceneControlsView : ControlsView <PdRecordEventDelegate, ControlsViewDelegate>

/// make sure to set this or nothing will happen ...
@property (weak, nonatomic) SceneManager *sceneManager;

#pragma mark UI

/// update the controls based on the current PureData settings
- (void)updateControls;

/// set left button to play icon
- (void)leftButtonToPlay;

/// set left button to pause icon
- (void)leftButtonToPause;

/// set right button to red filled record icon
- (void)rightButtonToRecord;

/// set right button to empty record icon
- (void)rightButtonToStopRecord;

@end
