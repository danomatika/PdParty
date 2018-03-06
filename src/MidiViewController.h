/*
 * Copyright (c) 2013, 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <UIKit/UIKit.h>

#import "MidiBridge.h"

/// midi settings view
@interface MidiViewController : UITableViewController <MidiBridgeDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *midiEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *virtualEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *networkMidiEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *multiDeviceModeSwitch;

- (IBAction)enableMidi:(id)sender;
- (IBAction)enableVirtual:(id)sender;
- (IBAction)enableNetworkMidi:(id)sender;
- (IBAction)enableMultiDeviceMode:(id)sender;

@end
