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

// Recording scene (wav file playback)
@interface RecordingScene : Scene

// path is to .wav file

@property (weak, nonatomic) UIView *controlsView; // rj controls
@property (weak, nonatomic) PureData *pureData;

@property (strong, nonatomic) NSString *file;
@property (strong, nonatomic) UIImageView *background;

+ (id)sceneWithParent:(UIView *)parent andControls:(UIView *)controls;

- (void)restartPlayback;

// returns true if a given path is a recording file aka .wav
+ (BOOL)isRecording:(NSString *)fullpath;

@end
