/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * This class is largely adapted from the LastFM app:
 * https://github.com/c99koder/lastfm-iphone/blob/master/Classes/UIViewController%2BNowPlayingButton.h
 *
 */
#import <UIKit/UIKit.h>

// adds a Now Playing button to the nav bar when a scene is loaded
@interface NowPlayingTableViewController : UITableViewController

// show the now playing button as the right item in the nav bar?
@property (assign, nonatomic) BOOL showNowPlayingButton;

// creates and pushes a PatchView onto the stack
- (void)nowPlayingPressed:(id)sender;

@end
