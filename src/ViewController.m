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
#import "ViewController.h"

#import "Gui.h"
#import "PdParser.h"
#import "PdFile.h"
#import "Log.h"

@implementation ViewController

@synthesize gui;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	gui = [[Gui alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	// load gui
	gui.bounds = self.view.bounds;
	[gui addWidgetsFromPatch:[[NSBundle mainBundle] pathForResource:@"gui" ofType:@"pd"]];
	gui.currentPatch = [PdFile openFileNamed:@"gui.pd" path:[[NSBundle mainBundle] bundlePath]];
	for(Widget *widget in gui.widgets) {
		[self.view addSubview:widget];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
