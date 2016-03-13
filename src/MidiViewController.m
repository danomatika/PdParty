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

@interface MidiViewController () {
	Midi *midi;
}
@end

@implementation MidiViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// set midi pointer
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	midi = app.midi;
	midi.delegate = self;
	
	// make sure the tableView knows about our dynamic cells
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MidiInputCell"];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MidiOutputCell"];
	
	self.midiEnabledSwitch.on = midi.isEnabled;
	self.networkMidiEnabledSwitch.on = midi.isNetworkEnabled;
	self.virtualInputEnabledSwitch.on = midi.isVirtualInputEnabled;
	self.virtualOutputEnabledSwitch.on = midi.isVirtualOutputEnabled;
}

- (void)dealloc {
	midi.delegate = nil;
}

// lock orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableMidi:(id)sender {
	midi.enabled = self.midiEnabledSwitch.isOn;
	
	// reload everything
	self.networkMidiEnabledSwitch.on = midi.isNetworkEnabled;
	self.virtualInputEnabledSwitch.on = midi.isVirtualInputEnabled;
	self.virtualOutputEnabledSwitch.on = midi.isVirtualOutputEnabled;
	[self.tableView reloadData];
}

- (IBAction)enableNetworkMidi:(id)sender {
	midi.networkEnabled = self.networkMidiEnabledSwitch.isOn;
}

- (IBAction)enableVirtualInput:(id)sender {
	midi.virtualInputEnabled = self.virtualInputEnabledSwitch.isOn;
	[self.tableView reloadData];
}

- (IBAction)enableVirtualOutput:(id)sender {
	midi.virtualOutputEnabled = self.virtualOutputEnabledSwitch.isOn;
	[self.tableView reloadData];
}

#pragma mark UITableViewController

// from http://code-ninja.org/blog/2012/02/29/ios-quick-tip-programmatically-hiding-sections-of-a-uitableview-with-static-cells/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		// hide cells based on midi status
		return midi.isEnabled ? 2 : 1; // change back to 4 to reenable virtual port controls
	}
	else if(section == 1) {
		return midi.inputs.count;
	}
	else if(section == 2) {
		return midi.outputs.count;
	}
	
	// default, just in case
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Customize the appearance of table view cells.
	
	UITableViewCell *cell;
	
	if(indexPath.section == 1) { // inputs
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiInputCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MidiInputCell"];
		}
		cell.userInteractionEnabled = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = [[midi.inputs objectAtIndex:indexPath.row] name];
	}
	else if(indexPath.section == 2) { // outputs
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiOutputCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MidiOutputCell"];
		}
		cell.userInteractionEnabled = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = [[midi.outputs objectAtIndex:indexPath.row] name];
	}
	else { // section 0: static cells
		cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	}
	
	return cell;
}

// the following are largely from this post https://devforums.apple.com/message/502990#502990
// on mixing static & dynamic table sections which basically requires overriding all
// methods which take an indexPath in order to avoid index out of bounds exceptions with
// the dynamic sections
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

// if a dynamic section, make all rows the same height as row 0
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 1 || indexPath.section == 2) {
		return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	}
	else {
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	}
}

// if dynamic section make all rows the same indentation level as row 0
-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 1 || indexPath.section == 2) {
		return [super tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	}
	else {
		return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
	}
}

// shouldn't be called since nothing is selectable
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark MidiConnectionDelegate

// reload inputs section
- (void)midiInputConnectionEvent {
	NSRange range = NSMakeRange(1, 1);
	NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];                                     
	[self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
}

// reload outputs section
- (void)midiOutputConnectionEvent {
	NSRange range = NSMakeRange(2, 1);
	NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];                                     
	[self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
