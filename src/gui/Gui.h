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
#import "Widget.h"

#import "Log.h"
#import "Util.h"

/// default pd gui font, loading custom fonts:
/// http://stackoverflow.com/questions/11047900/cant-load-custom-font-on-ios
#define GUI_FONT_NAME @"DejaVu Sans Mono"

/// pd gui wraps lines at 60 chars unless width is set
#define GUI_LINE_WRAP 60

/// widget size scaling modes
typedef enum {
	/// simple fit using scaleX for both width & height
	/// this is the original scale mode, may have issues on wide landscape views
	GuiScaleModeHorz = 0,
	/// fit by scaling widget width & height based on view aspect ratio:
	/// * portrait: scaleX
	/// * landscape: scaleY
	/// * square: scaleX & scaleY
	/// this will scale widgets down to fit view which preserving widget aspect
	GuiScaleModeAspect = 1,
	/// fill by stretching to fit to view
	/// scale widget width by scaleX & widget height by scaleY
	GuiScaleModeFill = 2
} GuiScaleMode;

@class PdFile;

/// Widget array wrapper, loads Widgets from atom line string arrays
@interface Gui : NSObject

/// widget array
@property (strong, nonatomic) NSMutableArray *widgets;

#pragma mark Patch Properties

/// current view size, used to determine screen scaling
@property (assign, nonatomic) CGSize parentViewSize;

/// pixel size of original pd patch
@property (assign, readonly, nonatomic) int patchWidth;
@property (assign, readonly, nonatomic) int patchHeight;

/// is the gui being displayed rotated from the original pd patch preferred
/// orientation? applied on next update to parentViewSize or viewport
@property (assign, nonatomic) BOOL isRotated;

/// base font name, default is GUI_FONT_NAME
/// setting to nil resets to default
@property (strong, nonatomic) NSString *fontName;

/// font size loaded from patch
@property (assign, readonly, nonatomic) int fontSize;

#pragma mark Scaling Properties

/// scale mode, default GuiScaleModeAspect
@property (assign, nonatomic) GuiScaleMode scaleMode;

/// x axis scale amount between parent view size and original patch size,
/// calculated when view size is set
@property (assign, readonly, nonatomic) float scaleX;

/// y axis scale amount between parent view size and original patch size,
/// calculated when view size is set
@property (assign, readonly, nonatomic) float scaleY;

/// widget width scaling, depending on scale mode
@property (assign, readonly, nonatomic) float scaleWidth;

/// widget height scaling, depending on scale mode
@property (assign, readonly, nonatomic) float scaleHeight;

/// line width based on current scale values
@property (assign, readonly, nonatomic) float lineWidth;

#pragma mark Viewport Properties

/// optional patch (sub) viewport in pixel size of original pd patch
@property (assign, nonatomic) CGRect viewport;

/// reset viewport back to patch size
- (void)resetViewport;

#pragma mark Add Widgets

// add a widget using a given atom line (array of NSStrings)

// pd
- (void)addNumber:(NSArray *)atomLine;
- (void)addSymbol:(NSArray *)atomLine;
- (void)addComment:(NSArray *)atomLine;

// iem
- (void)addBang:(NSArray *)atomLine;
- (void)addToggle:(NSArray *)atomLine;
- (void)addSlider:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation;
- (void)addRadio:(NSArray *)atomLine withOrientation:(WidgetOrientation)orientation;
- (void)addNumber2:(NSArray *)atomLine;
- (void)addVUMeter:(NSArray *)atomLine;
- (void)addCanvas:(NSArray *)atomLine;

/// add a widget using the object type name, returns YES if type handled
/// subclass this to add additional type creation & don't forget to call super
///
/// level refers to the patch canvas level where:
///   - 1 is the top level canvas
///   - >1 are sub patches
///
/// this allows for detecting non-drawable send/receive widgets in sub patches
- (BOOL)addObjectType:(NSString *)type fromAtomLine:(NSArray *)atomLine atLevel:(int)level;

/// add widgets from an array of atom lines
- (void)addWidgetsFromAtomLines:(NSArray *)lines;

/// add widgets from a pd patch
- (void)addWidgetsFromPatch:(NSString *)patch;

#pragma mark Manipulate Widgets

/// init widgets with patch $0 value
- (void)initWidgetsFromPatch:(PdFile *)patch;

/// init widgets with patch $0 value and add them as subviews to view
- (void)initWidgetsFromPatch:(PdFile *)patch andAddToView:(UIView *)view;

/// reposition/resize widgets based on scale amounts & font size
- (void)reshapeWidgets;

/// remove all widgets from their super view, does not delete
- (void)removeWidgetsFromSuperview;

/// remove all widgets, deletes
- (void)removeAllWidgets;

#pragma mark Utils

/// replace any occurrances of "//$0" or "#0" with the given patches' dollar zero id
- (NSString *)replaceDollarZeroStringsIn:(NSString *)string fromPatch:(PdFile *)patch;

/// convert atom string empty values to an empty string
/// nil, @"-", & @"empty" -> @""
+ (NSString *)filterEmptyStringValues:(NSString *)atom;

@end
