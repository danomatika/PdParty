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

// osc settings view
@interface OscViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *connectionEnabledSwitch;
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UITextField *outgoingPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *incomingPortTextField;
@property (weak, nonatomic) IBOutlet UILabel *localHostLabel;

- (IBAction)enableOscConnection:(id)sender;
- (IBAction)setHost:(id)sender;
- (IBAction)setOutgoingPort:(id)sender;
- (IBAction)setIncomingPort:(id)sender;

@end
