//
//  MasterViewController.h
//  PdParty
//
//  Created by Dan Wilcox on 1/11/13.
//  Copyright (c) 2013 Dan Wilcox. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
