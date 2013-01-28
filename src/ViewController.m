//
//  ViewController.m
//  PdParty
//
//  Created by Dan Wilcox on 1/27/13.
//  Copyright (c) 2013 danomatika. All rights reserved.
//

#import "ViewController.h"

#import "Gui.h"
#import "PdParser.h"
#import "Log.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize gui;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	gui = [[Gui alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	gui.bounds = self.view.bounds;
	
	// load gui
	NSArray *atoms = [PdParser getAtomLines:[PdParser readPatch:[[NSBundle mainBundle] pathForResource:@"gui" ofType:@"pd"]]];
	[PdParser printAtoms:atoms];
	[gui buildGui:atoms];
	
	for(Widget *widget in gui.widgets) {
		[self.view addSubview:widget];
		DDLogInfo(@"widget %f %f %f %f",
			widget.frame.origin.x, widget.frame.origin.y,
			CGRectGetWidth(widget.frame), CGRectGetHeight(widget.frame));
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
