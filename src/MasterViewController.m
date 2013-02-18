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
#import "MasterViewController.h"

#import "DetailViewController.h"
#import "Log.h"
#import "Util.h"

@interface MasterViewController () {}
@property (strong) NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)awakeFromNib {
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
	self.objects = [[NSMutableArray alloc] init];
    [super awakeFromNib];
}

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
	[super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
		
	self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	
	// error codes: https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
	NSError *error;
	NSArray *contents;
	
	// remove existing folder
	NSString* testPatchesPath = [[Util documentsPath] stringByAppendingPathComponent:@"tests"];
	if([[NSFileManager defaultManager] fileExistsAtPath:testPatchesPath]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:testPatchesPath error:&error]) {
			DDLogError(@"Couldn't remove %@, error: %@", testPatchesPath, error.localizedDescription);
		}
	}
	else {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:testPatchesPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			DDLogError(@"Couldn't create %@, error: %@", testPatchesPath, error.localizedDescription);
		}
	}
	
	// copy patches into Documents folder
	NSString *patchesPath = [[Util bundlePath] stringByAppendingPathComponent:@"patches"];
	contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:patchesPath error:&error];
	if(!contents) {
		DDLogError(@"Couldn't load files in path %@, error: %@", patchesPath, error.localizedDescription);
		return;
	}
	DDLogVerbose(@"Found %d paths in patches resource folder", contents.count);
	
	for(NSString *p in contents) {
		NSString *filePath = [patchesPath stringByAppendingPathComponent:p];
		DDLogVerbose(@"Copying %@", p);
		if(![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:testPatchesPath error:&error]) {
			DDLogError(@"Couldn't copy %@ to %@, error: %@", filePath, testPatchesPath, error.localizedDescription);
		}
	}
	
	// search for files in the documents path
	contents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[Util documentsPath] error:&error];
	if(!contents) {
		DDLogError(@"Couldn't load files in path %@, error: %@", [Util documentsPath], error.localizedDescription);
		return;
	}
	DDLogVerbose(@"Found %d paths", contents.count);
	
	for(NSString *p in contents) {
		DDLogVerbose(@"	%@", p);
		[self.objects addObject:p];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_objects.count+1 inSection:0];
		[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if(!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	NSDate *object = self.objects[indexPath.row];
	cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if(editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDate *object = _objects[indexPath.row];
		self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
