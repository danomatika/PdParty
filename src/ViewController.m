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
#import "PdFile.h"
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
