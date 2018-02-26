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

@class PureData;
@class AVPlayerViewController;
@class AVPlayerLayer;

/// Recording scene (wav file playback)
/// path is to .wav file
@interface RecordingScene : Scene

@property (weak, nonatomic) PureData *pureData;

/// wav file to play
@property (strong, nonatomic) NSString *file;

/// file player and controls
@property (strong, nonatomic) AVPlayerViewController *player;

/// square background image (nominally 320x320)
@property (strong, nonatomic) UIImageView *background;

/// extended info label, just filename for now
@property (strong, nonatomic) UILabel *infoLabel;

//+ (id)sceneWithParent:(UIView *)parent andPureData:(PureData *)pureData;
+ (id)sceneWithParent:(UIView *)parent;

/// restart playback at the beginning
//- (void)restartPlayback;

/// returns true if a given path is a recording file aka .wav
+ (BOOL)isRecording:(NSString *)fullpath;

@end
