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
#import "IEMWidget.h"

@interface Canvas : IEMWidget
@end

@class Gui;

@protocol ViewPortDelegate <NSObject>
- (void)receivePositionX:(float)x Y:(float)y;
- (void)receiveSizeW:(float)w H:(float)h;
@end

@interface ViewPortCanvas : Canvas
@property (assign, nonatomic) id<ViewPortDelegate> delegate;
@end
