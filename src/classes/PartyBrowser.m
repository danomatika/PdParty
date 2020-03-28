/*
 * Copyright (c) 2015 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "PartyBrowser.h"

#import "Log.h"
#import "AllScenes.h"

@implementation PartyBrowser

// lock orientation on iPhone
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if(Util.isDeviceATablet) {
		return UIInterfaceOrientationMaskAll;
	}
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Utils

+ (BOOL)isZipFile:(NSString *)path {
	NSString *ext = path.pathExtension;
	return ([ext isEqualToString:@"zip"] ||
			[ext isEqualToString:@"pdz"] ||
			[ext isEqualToString:@"rjz"]);
}

#pragma mark Subclassing

// disable swipe back gesture on iPhone as it interferes with patch view gestures
- (void)viewDidLoad {
	[super viewDidLoad];
	if(!Util.isDeviceATablet) {
		if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
			self.navigationController.interactivePopGestureRecognizer.enabled = NO;
		}
	}
}

- (Browser *)newBrowser {
	return [[PartyBrowser alloc] initWithStyle:self.tableView.style];
}

#pragma mark BrowserDataDelegate

- (BOOL)browser:(Browser *)browser shouldAddPath:(NSString *)path isDir:(BOOL)isDir {
	NSError *error;
	NSString *file = path.lastPathComponent;
	if(isDir) {
		// keep Documents/Inbox from paths array since we don't have permission to delete it,
		// this is where the system copies files when using AirDrop or the "Open With ..." mechanism
		if(self.isRootLayer && [path.lastPathComponent isEqualToString:@"Inbox"]) {
			return NO;
		}
		// remove __MACOSX added to zip files by macOS
		if([file isEqualToString:@"__MACOSX"]) {
			if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
				DDLogError(@"FileBrowser: couldn't remove %@, error: %@", file, error.localizedDescription);
			}
			else {
				DDLogVerbose(@"FileBrowser: removed %@", file);
				return NO;
			}
		}
		return YES;
	}
	else {
		if(self.extensions) {
			if([self pathHasAllowedExtension:file]) { // add allowed extensions
				return YES;
			}
		}
		else {
			if([PatchScene isPatchFile:path]) { // add patch
				return YES;
			}
			else if([RecordingScene isRecording:path]) { // add recordings
				return YES;
			}
			else if([PartyBrowser isZipFile:path]) { // add zipfiles
				return YES;
			}
			// remove Finder DS_Store garbage (created over WebDAV)
			else if([file isEqualToString:@"._.DS_Store"] || [file isEqualToString:@".DS_Store"]) {
				if(![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
					DDLogError(@"FileBrowser: couldn't remove %@, error: %@", file, error.localizedDescription);
				}
				else {
					DDLogVerbose(@"FileBrowser: removed %@", file);
					return NO;
				}
			}
		}
	}
	DDLogVerbose(@"Browser: dropped path: %@", path.lastPathComponent);
	return NO;
}

// make sure we can't navigate into known scene folder types
- (BOOL)browser:(Browser *)browser isPathSelectable:(NSString *)path isDir:(BOOL)isDir {
	if(browser.mode == BrowserModeMove) {
		if([RjScene isRjDjDirectory:path] ||
		   [DroidScene isDroidPartyDirectory:path] ||
		   [PartyScene isPdPartyDirectory:path]) {
			return NO;
		}
	}
	return YES;
}

- (void)browser:(Browser *)browser styleCell:(UITableViewCell *)cell forPath:(NSString *)path isDir:(BOOL)isDir isSelectable:(BOOL)isSelectable {
	[super browser:self styleCell:cell forPath:path isDir:isDir isSelectable:isSelectable];
	cell.detailTextLabel.text = @"";
	if(isDir) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		if([RjScene isRjDjDirectory:path]) {
			
			// thumbnail
			UIImage *thumb = [RjScene thumbnailForSceneAt:path];
			if(thumb) {
				cell.imageView.image = thumb;
			}
			else {
				cell.imageView.image = [UIImage imageNamed:@"folder"];
			}
			
			// info
			NSDictionary *info = [RjScene infoForSceneAt:path];
			if(info) {
				if(info[@"name"]) {
					cell.textLabel.text = info[@"name"];
				}
				else {
					cell.textLabel.text = path.lastPathComponent;
				}
				if(info[@"author"]) {
					cell.detailTextLabel.text = info[@"author"];
				}
			}
		}
		else if([DroidScene isDroidPartyDirectory:path]) {
			cell.imageView.image = [UIImage imageNamed:@"droidparty"];
		}
		else if([PartyScene isPdPartyDirectory:path]) {
		
			// thumbnail
			UIImage *thumb = [PartyScene thumbnailForSceneAt:path];
			if(thumb) {
				cell.imageView.image = thumb;
			}
			else {
				cell.imageView.image = [UIImage imageNamed:@"pdparty"];
			}
		
			// info
			NSDictionary *info = [PartyScene infoForSceneAt:path];
			if(info) {
				if(info[@"name"]) {
					cell.textLabel.text = info[@"name"];
				}
				else {
					cell.textLabel.text = path.lastPathComponent;
				}
				if(info[@"author"]) {
					cell.detailTextLabel.text = info[@"author"];
				}
			}
		}
		else {
			cell.imageView.image = [UIImage imageNamed:@"folder"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	else { // files
		if([PartyBrowser isZipFile:path]) {
			cell.imageView.image = [UIImage imageNamed:@"archive"];
		}
		else if([RecordingScene isRecording:path]) {
			cell.imageView.image = [UIImage imageNamed:@"tape"];
		}
		else if([PatchScene isPatchFile:path]) {
			cell.imageView.image = [UIImage imageNamed:@"patch"];
		}
		else {
			cell.imageView.image = [UIImage imageNamed:@"file"];
		}
	}
}

@end
