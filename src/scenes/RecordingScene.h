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
@class ControlsView;

// Recording scene (wav file playback)
@interface RecordingScene : Scene

// path is to .wav file

@property (weak, nonatomic) PureData *pureData;
@property (weak, nonatomic) ControlsView *controlsView;

@property (strong, nonatomic) NSString *file;
@property (strong, nonatomic) UIImageView *background;

+ (id)sceneWithParent:(UIView *)parent andPureData:(PureData *)pureData;

- (void)restartPlayback;

// returns true if a given path is a recording file aka .wav
+ (BOOL)isRecording:(NSString *)fullpath;

@end
