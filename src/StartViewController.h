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

@class WebServer;

// start page view
@interface StartViewController : UITableViewController

#pragma mark Connections

@property (nonatomic, weak) IBOutlet UILabel *oscLabel;

#pragma mark WebServer

@property (nonatomic, strong) WebServer *server;

@property (nonatomic, weak) IBOutlet UISwitch *serverEnabledSwitch;
@property (nonatomic, weak) IBOutlet UILabel *serverPortLabel;
@property (nonatomic, weak) IBOutlet UITextField *serverPortTextField;

- (IBAction)enableWebServer:(id)sender;

- (IBAction)setWebServerPort:(id)sender;

@end
