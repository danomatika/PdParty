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
#import "MidiViewController.h"

#import "AppDelegate.h"
#import <CoreAudioKit/CoreAudioKit.h>

#define SETTINGS_SECTION 0
#define CHANNELS_SECTION 1
#define INPUTS_SECTION   2
#define OUTPUTS_SECTION  3

#define BLUETOOTH_ROW 3

#pragma mark - MidiConnectionCell

// custom cell so default init sets right detail style
@interface MidiConnectionCell : UITableViewCell
@end
@implementation MidiConnectionCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
	return self;
}
@end

#pragma mark - MidiViewController

@implementation MidiViewController {
	MidiBridge *midi;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set midi pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	midi = app.midi;
	
	// make sure the tableView knows about our dynamic cell type
	[self.tableView registerClass:MidiConnectionCell.class forCellReuseIdentifier:@"MidiConnectionCell"];
	
	self.midiEnabledSwitch.on = midi.enabled;
	self.virtualEnabledSwitch.on = midi.virtualEnabled;
	self.networkMidiEnabledSwitch.on = midi.networkEnabled;
	self.multiDeviceModeSwitch.on = midi.multiDeviceMode;


}

- (void)viewWillAppear:(BOOL)animated {
	midi.delegate = self;
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	midi.delegate = nil;
	[super viewWillDisappear:animated];
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableMidi:(id)sender {
	midi.enabled = self.midiEnabledSwitch.isOn;
	
	// reload everything
	self.virtualEnabledSwitch.on = midi.virtualEnabled;
	self.networkMidiEnabledSwitch.on = midi.networkEnabled;
	self.multiDeviceModeSwitch.on = midi.multiDeviceMode;
	[self.tableView reloadData];
}

- (IBAction)enableVirtual:(id)sender {
	midi.virtualEnabled = self.virtualEnabledSwitch.isOn;
}

- (IBAction)enableNetworkMidi:(id)sender {
	midi.networkEnabled = self.networkMidiEnabledSwitch.isOn;
}

- (IBAction)enableMultiDeviceMode:(id)sender {
	midi.multiDeviceMode = self.multiDeviceModeSwitch.isOn;
	// reloading the table view loads the footer text
	[self.tableView reloadData];
}

#pragma mark UITableViewController

// hide cells based on midi status
// from http://code-ninja.org/blog/2012/02/29/ios-quick-tip-programmatically-hiding-sections-of-a-uitableview-with-static-cells/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == SETTINGS_SECTION) {
		return (midi.enabled ? 4 : 1);
	}
	else if(section == CHANNELS_SECTION) {
		return (midi.enabled ? 1 : 0);
	}
	else if(section == INPUTS_SECTION) {
		return midi.inputs.count;
	}
	else if(section == OUTPUTS_SECTION) {
		return midi.outputs.count;
	}
	
	// default, just in case
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Customize the appearance of table view cells.
	
	UITableViewCell *cell;
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiConnectionCell" forIndexPath:indexPath];
		if(!cell) {
			cell = [[MidiConnectionCell alloc] initWithStyle:UITableViewCellStyleValue1
			                                 reuseIdentifier:@"MidiConnectionCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.textLabel.textColor = [UIColor blackColor];
		cell.detailTextLabel.textColor = [UIColor blackColor];
		cell.userInteractionEnabled = NO;

		MidiConnection *connection = (indexPath.section == INPUTS_SECTION ?
		                              midi.inputs[indexPath.row] :
		                              midi.outputs[indexPath.row]);
		if(connection) {
			cell.textLabel.text = [NSString stringWithFormat:@"%d", connection.port+1];
			cell.detailTextLabel.text = connection.name;
		}
	}
	else { // section 0 or 1: static cells
		cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
		if(indexPath.section == SETTINGS_SECTION && indexPath.row == BLUETOOTH_ROW) {
			// disable Bluetooth selection?
			BOOL enabled = [Util deviceSupportsBluetoothLE];
			cell.userInteractionEnabled = enabled;
			for(UIView *view in cell.contentView.subviews) {
				if([view isKindOfClass:UILabel.class]) {
					[(UILabel *)view setEnabled:enabled];
				}
			}
		}
	}
	
	return cell;
}

// hide headers when disabled
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section) {
		case CHANNELS_SECTION:
			if(midi.enabled) {
				return @"Channels";
			}
		case INPUTS_SECTION:
			if(midi.enabled) {
				return @"Inputs";
			}
		case OUTPUTS_SECTION:
			if(midi.enabled) {
				return @"Outputs";
			}
		default:
			return nil;
	}
}

// hide footers when disabled
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch(section) {
		case SETTINGS_SECTION:
			if(midi.enabled) {
				return @"Max 4 inputs & 4 outputs";
			}
		case CHANNELS_SECTION:
			if(midi.enabled) {
				if(midi.multiDeviceMode) {
					return @"Dev channels: 1 (1-16), 2 (17-32), 3 (33-48), 4 (49-64)";
				}
				else {
					return @"Devices share channels 1-16";
				}
			}
		default:
			return nil;
	}
}

// the following are largely from this post https://devforums.apple.com/message/502990#502990
// on mixing static & dynamic table sections which basically requires overriding all
// methods which take an indexPath in order to avoid index out of bounds exceptions with
// the dynamic sections
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

// if a dynamic section, make all rows the same height as row 0
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	}
	else {
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	}
}

// if dynamic section make all rows the same indentation level as row 0
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		return [super tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	}
	else {
		return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
	}
}

// nothing is selectable except for Bluetooth MIDI
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section == SETTINGS_SECTION && indexPath.row == BLUETOOTH_ROW) {
		/// launch Bluetooth MIDI controller
		/// https://developer.apple.com/library/content/qa/qa1831/_index.html
		CABTMIDICentralViewController *controller = [CABTMIDICentralViewController new];
    	[self.navigationController pushViewController:controller animated:YES];
	}
}

#pragma mark MidiBridgeDelegate

// reload input and output sections, does these together otherwise table view
// will crash when reloading one section while the number of ports in the other
// section has changed as well
- (void)midiConnectionsChanged {
	NSRange range = NSMakeRange(INPUTS_SECTION, 2); // sections 2 & 3
	NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
	[self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
