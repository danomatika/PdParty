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

/// osc settings view
@interface OscViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *oscEnabledSwitch;
@property (weak, nonatomic) IBOutlet UITextField *sendHostTextField;
@property (weak, nonatomic) IBOutlet UITextField *sendPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *listenPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *listenGroupTextField;
@property (weak, nonatomic) IBOutlet UILabel *localHostLabel;

- (IBAction)enableOsc:(id)sender;
- (IBAction)setSendHost:(id)sender;
- (IBAction)setSendPort:(id)sender;
- (IBAction)setListenPort:(id)sender;
- (IBAction)setListenGroup:(id)sender;

@end
