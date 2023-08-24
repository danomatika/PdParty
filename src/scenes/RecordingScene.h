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
#import "Scene.h"
#import "PlayerControlsView.h"

@class AVPlayer;

/// Recording scene (wav or aiff file playback)
/// scene path is to .wav/.wave/.aif/.aiff file
/// square background image (nominally 320x320)
@interface RecordingScene : Scene <ControlsViewDelegate>

/// file to play
@property (strong, nonatomic) NSString *file;

/// file player
@property (strong, nonatomic) AVPlayer *player;

/// extended info label for iPhone as filename is cut off in nav bar
@property (strong, nonatomic) UILabel *infoLabel;

/// player controls
@property (strong, nonatomic) PlayerControlsView *controlsView;

+ (id)sceneWithParent:(UIView *)parent;

/// returns YES if a given path is a recording file aka .wav/.wave/.aif/.aiff
+ (BOOL)isRecording:(NSString *)fullpath;

@end
