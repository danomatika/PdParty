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

@class Osc;

// start page view
@interface OscViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UISwitch *connectionEnabledSwitch;
@property (nonatomic, weak) IBOutlet UITextField *hostTextField;
@property (nonatomic, weak) IBOutlet UITextField *outgoingPortTextField;
@property (nonatomic, weak) IBOutlet UITextField *incomingPortTextField;
@property (nonatomic, weak) IBOutlet UILabel *localHostLabel;

- (IBAction)enableOscConnection:(id)sender;
- (IBAction)setHost:(id)sender;
- (IBAction)setOutgoingPort:(id)sender;
- (IBAction)setIncomingPort:(id)sender;

@end
