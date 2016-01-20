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

/// Recording scene (wav file playback)
/// path is to .wav file
@interface RecordingScene : Scene

@property (weak, nonatomic) PureData *pureData; //< playback handled in pd

@property (strong, nonatomic) NSString *file; //< wav file to play

/// sqaure background image (nominally 320x320)
@property (strong, nonatomic) UIImageView *background;

+ (id)sceneWithParent:(UIView *)parent andPureData:(PureData *)pureData;

/// restart playback at the beginning
- (void)restartPlayback;

/// returns true if a given path is a recording file aka .wav
+ (BOOL)isRecording:(NSString *)fullpath;

@end
