/*
 * Copyright (c) 2016 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

/// open a url, uses app scene folder for relative path
/// set sceneRotationsOnly to YES to lock rotatiosn to the current scene
- (void)openURL:(NSURL *)url withTitle:(NSString *)title sceneRotationsOnly:(BOOL)sceneRotationsOnly;

@end
