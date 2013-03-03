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

@class Gui;

// DetailViewController for patches/scenes 
@interface PatchViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong) Gui *gui;

@property (strong, nonatomic) id detailItem;

@end
