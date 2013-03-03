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
#import "BrowserViewController.h"

#import "PatchViewController.h"
#import "Log.h"
#import "Util.h"

// has the first view been loaded?
static BOOL firstViewLoaded = NO;

@implementation BrowserViewController

- (void)awakeFromNib {
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
	self.pathArray = [[NSMutableArray alloc] init];
//	self.currentDir = [Util documentsPath];
    [super awakeFromNib];
}

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
	[super viewDidLoad];
	
	// load the documents path
	if(!firstViewLoaded) {
		self.patchViewController = (PatchViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
		[self loadDirectory:[Util documentsPath]];
		firstViewLoaded = YES;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark File Browsing

// file access error codes:
// https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html

- (void)loadDirectory:(NSString *)dirPath {

	NSError *error;

	DDLogVerbose(@"Loading directory %@", dirPath);

	// search for files in the given path
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
	if(!contents) {
		DDLogError(@"Couldn't load directory %@, error: %@", dirPath, error.localizedDescription);
		return;
	}
	
	// add contents to pathArray as absolute paths
	DDLogVerbose(@"Found %d paths", contents.count);
	for(NSString *p in contents) {
		DDLogVerbose(@"	%@", p);
		[self.pathArray addObject:[dirPath stringByAppendingPathComponent:p]];
	}
	[self.tableView reloadData];
	
	self.navigationItem.title = [dirPath lastPathComponent]; // set title of back button
	self.currentDir = dirPath;
	self.navigationController.title = [dirPath lastPathComponent]; // set title of current dir
	DDLogVerbose(@"Current directory now %@", dirPath);
}

#pragma mark UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return self.pathArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Customize the appearance of table view cells.
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	NSString *path = self.pathArray[indexPath.row];
	
//  BOOL isDir;
//	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
//		if(isDir) {
//			//cell.imageView =
//		}
//		else {
//			// is patch
//			//cell.imageView =
//		}
//	}
//	else {
//		DDLogError(@"Can't select row in table view, file dosen't exist: %@", path);
//		[tableView deselectRowAtIndexPath:indexPath animated:NO];
//	}

	cell.textLabel.text = [path lastPathComponent];
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [self.pathArray removeObjectAtIndex:indexPath.row];
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
    
	NSString *path = self.pathArray[indexPath.row];
	
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if(isDir) {
		
			// create a new browser table view and push it on the stack 
			UIStoryboard *sb;
			if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				sb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
			}
			else {
				sb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
			}
			BrowserViewController *browserLayer = [sb instantiateViewControllerWithIdentifier:@"BrowserViewController"];
			browserLayer.patchViewController = self.patchViewController;
			[browserLayer loadDirectory:path];
			[self.navigationController pushViewController:browserLayer animated:YES];
		}
		else {
			if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				self.patchViewController.detailItem = path;
			}
			else {
				[self performSegueWithIdentifier:@"runPatch" sender:self];
			}
		}
	}
	else {
		DDLogError(@"Can't select row in table view, file dosen't exist: %@", path);
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
//	if([[segue identifier] isEqualToString:@"runPatch"]) {
//		[self loadDirectory:sender];
//	}
//	else
	if([[segue identifier] isEqualToString:@"runPatch"]) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSString *path = self.pathArray[indexPath.row];
		[[segue destinationViewController] setDetailItem:path];
    }
}

@end
