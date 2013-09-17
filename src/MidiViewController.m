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
}

- (void)dealloc {
	midi.delegate = nil;
}

// lock orientation
- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Settings

- (IBAction)enableMidi:(id)sender {
	midi.enabled = self.midiEnabledSwitch.isOn;
	[self.tableView reloadData];
}

- (IBAction)enableNetworkMidi:(id)sender {
	midi.networkEnabled = self.networkMidiEnabledSwitch.isOn;
}

#pragma mark UITableViewController

// from http://code-ninja.org/blog/2012/02/29/ios-quick-tip-programmatically-hiding-sections-of-a-uitableview-with-static-cells/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if(section == 0) {
		// hide cells based on midi status
		return midi.isEnabled ? 2 : 1;
	}
	else if(section == 1) {
		return midi.midi.sources.count;
	}
	else if(section == 2) {
		return midi.midi.destinations.count;
	}
	
	// default, just in case
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Customize the appearance of table view cells.
	
	UITableViewCell *cell;
	
	if(indexPath.section == 1) { // inputs
		NSLog(@"%d midi sources", midi.midi.sources.count);
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiInputCell" forIndexPath:indexPath];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MidiInputCell"];
		}
		cell.textLabel.text = [[midi.midi.sources objectAtIndex:indexPath.row] name];
	}
	else if(indexPath.section == 2) { // outputs
		NSLog(@"%d midi destinations", midi.midi.destinations.count);
		cell = [tableView dequeueReusableCellWithIdentifier:@"MidiOutputCell" forIndexPath:indexPath];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MidiOutputCell"];
		}
		cell.textLabel.text = [[midi.midi.destinations objectAtIndex:indexPath.row] name];
	}
	else { // section 0: static cells
		cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	}
	
    return cell;
}

#pragma mark MidiConnectionDelegate

- (void)midiSourceConnectionEvent {
	// reload inputs section
	NSRange range = NSMakeRange(1, 1);
	NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];                                     
	[self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)midiDestinationConnectionEvent {
	// relaod outputs section
	NSRange range = NSMakeRange(2, 1);
	NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];                                     
	[self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
