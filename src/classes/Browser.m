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
#import "Browser.h"

#import "Log.h"
#import "AllScenes.h"

@implementation Browser

#pragma mark Utils

+ (BOOL)isZipFile:(NSString *)path {
	return ([[path pathExtension] isEqualToString:@"zip"] ||
			[[path pathExtension] isEqualToString:@"pdz"] ||
			[[path pathExtension] isEqualToString:@"rjz"]);
}

#pragma mark Subclassing

- (void)setup {
	[super setup];
}

- (BOOL)shouldAddPath:(NSString *)path isDir:(BOOL)isDir {
	if(isDir) {
		return YES;
	}
	else {
		NSError *error;
		NSString *file = [path lastPathComponent];
		if(self.extensions) {
			if([self pathHasAllowedExtension:file]) { // add allowed extensions
				return YES;
			}
		}
		else {
			if([[file pathExtension] isEqualToString:@"pd"]) { // add patch
				return YES;
			}
			else if([RecordingScene isRecording:path]) { // add recordings
				return YES;
			}
			else if([Browser isZipFile:path]) { // add zipfiles
				return YES;
			}
			// remove Finder DS_Store garbage (created over WebDAV) and __MACOSX added to zip files
			else if([file isEqualToString:@"__MACOSX"] ||
			   [file isEqualToString:@"._.DS_Store"] || [file isEqualToString:@".DS_Store"]) {
				if(![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
					DDLogError(@"FileBrowser: couldn't remove %@, error: %@", file, error.localizedDescription);
				}
				else {
					DDLogVerbose(@"FileBrowser: removed %@", file);
					return NO;
				}
			}
		}
	}
	DDLogVerbose(@"Browser: dropped path: %@", [path lastPathComponent]);
	return NO;
}

- (void)styleCell:(UITableViewCell *)cell forPath:(NSString *)path isDir:(BOOL)isDir isSelectable:(BOOL)isSelectable {
	[super styleCell:cell forPath:path isDir:isDir isSelectable:isSelectable];
	cell.detailTextLabel.text = @"";
	if(isDir) {
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
				if([info objectForKey:@"name"]) {
					cell.textLabel.text = [info objectForKey:@"name"];
				}
				else {
					cell.textLabel.text = [path lastPathComponent];
				}
				if([info objectForKey:@"author"]) {
					cell.detailTextLabel.text = [info objectForKey:@"author"];
				}
			}
		}
		else if([DroidScene isDroidPartyDirectory:path]) {
			cell.imageView.image = [UIImage imageNamed:@"android"];
		}
		else if([PartyScene isPdPartyDirectory:path]) {
			cell.imageView.image = [UIImage imageNamed:@"pdparty"];
		}
		else {
			cell.imageView.image = [UIImage imageNamed:@"folder"];
		}
	}
	else { // files
		if([Browser isZipFile:path]) {
			cell.imageView.image = [UIImage imageNamed:@"archive"];
		}
		else if([RecordingScene isRecording:path]) {
			cell.imageView.image = [UIImage imageNamed:@"audioFile"];
		}
		else {
			cell.imageView.image = [UIImage imageNamed:@"file"];
		}
	}
}

@end
