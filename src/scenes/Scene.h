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
#import <UIKit/UIKit.h>

#import "PureData.h"
#import "Gui.h"
#import "Log.h"
#import "Util.h"

// sensor type for querying scene info
typedef enum {
	SensorTypeAccel,
	SensorTypeGyro,
	SensorTypeLocation,
	SensorTypeCompass,
	SensorTypeMagnet
} SensorType;

/// base empty scene
@interface Scene : NSObject

/// scene type name string
@property (readonly, nonatomic) NSString *type;

@property (strong, nonatomic) PdFile *patch; //< currently loaded patch, if any
@property (readonly, nonatomic) NSString *name; //< scene instance name
@property (readonly, nonatomic) BOOL records; //< can this scene record? has a [soundoutput] object

/// rjdj-style scene info, probabaly loaded from a file, etc
@property (readonly, nonatomic) BOOL hasInfo; //< returns YES if the current info is loaded
@property (readonly, nonatomic) NSString *artist; //< scene artist name
@property (readonly, nonatomic) NSString *category; //< scene category
@property (readonly, nonatomic) NSString *description; //< scene description

/// set these before calling the open method
@property (weak, nonatomic) UIView *parentView; //< parent UIView
@property (weak, nonatomic) Gui *gui; //< PD gui (optional, leave nil if not used)

/// desired scene sample rate (default PARTY_SAMPLERATE)
@property (readonly, nonatomic) int sampleRate;

@property (readonly, nonatomic) BOOL requiresTouch; //< does the scene require touch events? (default NO)
@property (readonly, nonatomic) BOOL requiresControllers; //< does the scene require controller events? (default NO)
@property (readonly, nonatomic) BOOL requiresKeys; //< does the scene require key events? (default NO)

/// preferred orientations, all by default
@property (assign, nonatomic) UIInterfaceOrientationMask preferredOrientations;

/// does the scene require on screen controls?
@property (readonly, nonatomic) BOOL requiresOnscreenControls;
@property (readonly, nonatomic) int contentHeight; //< used for positioning controls

- (BOOL)open:(NSString *)path; //< expects full path
- (void)close;

/// reshape to fit current parent view size
- (void)reshape;

/// attempts to scale a touch within the parent view,
/// returns NO if touch not within current scene or scene doesn't require touch events
- (BOOL)scaleTouch:(UITouch *)touch forPos:(CGPoint *)pos;

/// returns YES if a sensor is required & should be started when opened (default NO)
- (BOOL)requiresSensor:(SensorType)sensor;

/// returns YES if a sensor is supported & can be started after opening (default NO)
- (BOOL)supportsSensor:(SensorType)sensor;

#pragma mark Util

/// add subfolders in a given directory to the PD search path
- (void)addSearchPathsIn:(NSString *)directory;

/// compute a preferred orientation via width & height aspect ratio
+ (UIInterfaceOrientationMask)orientationMaskFromWidth:(float)width andHeight:(float)height;

@end
