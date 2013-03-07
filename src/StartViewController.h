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

@property (strong, nonatomic) WebServer *server;

@property (weak, nonatomic) IBOutlet UISwitch *serverEnabledSwitch;
@property (weak, nonatomic) IBOutlet UILabel *serverPortLabel;
@property (weak, nonatomic) IBOutlet UITextField *serverPortTextField;

- (IBAction)enableWebServer:(id)sender;

- (IBAction)setWebServerPort:(id)sender;

@end
