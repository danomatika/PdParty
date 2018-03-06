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
#import "MidiViewController.h"

#import "AppDelegate.h"
#import <CoreAudioKit/CoreAudioKit.h>

#define SETTINGS_SECTION 0
#define CHANNELS_SECTION 1
#define INPUTS_SECTION   2
#define OUTPUTS_SECTION  3

#define BLUETOOTH_ROW 3

// placeholder string for unused i/o ports
#define EMPTY_CELL @"none"

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

	[self rightNavToEditButton];
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
	self.navigationItem.rightBarButtonItem.enabled = midi.multiDeviceMode;
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
	self.navigationItem.rightBarButtonItem.enabled = midi.multiDeviceMode;
	if(!midi.multiDeviceMode) {
		[self doneButtonPressed];
	}
	[self.tableView reloadData]; // reload footer text
}

- (void)editButtonPressed {
	[self.tableView setEditing:YES animated:YES];
	[self rightNavToDoneButton];
}

- (void)doneButtonPressed {
	[self.tableView setEditing:NO animated:YES];
	[self rightNavToEditButton];
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
		if(midi.enabled) {
			return (midi.multiDeviceMode ? MIDI_MAX_IO : midi.inputs.count);
		}
		return 0;
	}
	else if(section == OUTPUTS_SECTION) {
		if(midi.enabled) {
			return (midi.multiDeviceMode ? MIDI_MAX_IO : midi.inputs.count);
		}
		return 0;
	}
	
	// default, just in case
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Customize the appearance of table view cells.
	
	UITableViewCell *cell;
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiConnectionCell"];
		if(!cell) {
			cell = [[MidiConnectionCell alloc] initWithStyle:UITableViewCellStyleValue1
			                                 reuseIdentifier:@"MidiConnectionCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.textLabel.textColor = [UIColor blackColor];
		cell.detailTextLabel.textColor = [UIColor blackColor];

		BOOL enabled = NO;
		NSArray *array = (indexPath.section == INPUTS_SECTION ? midi.inputs : midi.outputs);
		MidiConnection *connection;
		if(midi.multiDeviceMode) {
			// try to find connection with matching port
			for(MidiConnection *c in array) {
				if(c.port == indexPath.row) {
					connection = c;
					break;
				}
			}
			enabled = YES;
		}
		else {
			connection = array[indexPath.row];
		}

		if(connection) {
			// existing connection
			cell.textLabel.text = connection.name;
			if(midi.multiDeviceMode) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", connection.port+1];
			}
			else {
				cell.detailTextLabel.text = @"";
			}
		}
		else {
			// dummy placeholder
			cell.textLabel.text = EMPTY_CELL;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", (int)indexPath.row+1];
			cell.textLabel.textColor = [UIColor lightGrayColor];
			cell.detailTextLabel.textColor = [UIColor lightGrayColor];
		}
		cell.textLabel.enabled = enabled;
		cell.detailTextLabel.enabled = enabled;
		cell.userInteractionEnabled = enabled;
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

// inputs & outputs can be reordered when editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		return YES;
	}
	return NO;
}

// inputs & outputs can be reordered when editing
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == INPUTS_SECTION || indexPath.section == OUTPUTS_SECTION) {
		return YES;
	}
	return NO;
}

// only allow reordering within sections
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if(sourceIndexPath.section != proposedDestinationIndexPath.section) {
		NSInteger row = 0;
		if(sourceIndexPath.section < proposedDestinationIndexPath.section) {
			row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
		}
    	return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
	}
	return proposedDestinationIndexPath;
}

// reorder inputs / outputs when editing
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(nonnull NSIndexPath *)sourceIndexPath toIndexPath:(nonnull NSIndexPath *)destinationIndexPath {
	if(sourceIndexPath.section == INPUTS_SECTION) {
		if([midi moveInputPort:(int)sourceIndexPath.row toPort:(int)destinationIndexPath.row]) {
			[tableView reloadData];
		}
	}
	else if(sourceIndexPath.section == OUTPUTS_SECTION) {
		if([midi moveOutputPort:(int)sourceIndexPath.row toPort:(int)destinationIndexPath.row]) {
			[tableView reloadData];
		}
	}
	else {
		// static sections, should never be called
		return;
	}
}

// don't indent while editing
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

// only moving, so no editing style
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

#pragma mark Private

- (void)rightNavToEditButton {
	self.navigationItem.rightBarButtonItem =
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
		                                              target:self
		                                              action:@selector(editButtonPressed)];
	self.navigationItem.rightBarButtonItem.enabled = (midi.enabled && midi.multiDeviceMode);
}

- (void)rightNavToDoneButton {
	self.navigationItem.rightBarButtonItem =
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		                                              target:self
		                                              action:@selector(doneButtonPressed)];
}

@end
