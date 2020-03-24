/*
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 * Adapted from ZipArchive: https://github.com/mattconnolly/ZipArchive.git
 *
 * Copyright (C) 2010-2012 Matt Connolly, Edward Patel, et al
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 #import "Unzip.h"
 #include "minizip/unzip.h"

@implementation Unzip {
	unzFile zipFile;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		zipFile = NULL;
	}
	return self;
}

- (void)dealloc {
	[self close];
}

- (BOOL)open:(NSString *)path {
	zipFile = unzOpen((const char*)[path UTF8String]);
	return zipFile != NULL;
}

- (BOOL)unzipTo:(NSString *)path overwrite:(BOOL)overwrite {
	BOOL success = YES;
	int ret = unzGoToFirstFile(zipFile);
	unsigned char buffer[4096] = {0};
	NSFileManager *fman = NSFileManager.defaultManager;
	if(ret != UNZ_OK) {
		return NO;
	}
	while(ret == UNZ_OK && UNZ_OK != UNZ_END_OF_LIST_OF_FILE) {
		ret = unzOpenCurrentFile(zipFile);
		if(ret != UNZ_OK) {
			success = NO;
			break;
		}

		// read data and write to file
		int read;
		unz_file_info fileInfo = {0};
		ret = unzGetCurrentFileInfo(zipFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
		if(ret != UNZ_OK) {
			success = NO;
			unzCloseCurrentFile(zipFile);
			break;
		}
		char *filename = (char *) malloc(fileInfo.size_filename+1);
		unzGetCurrentFileInfo(zipFile, &fileInfo, filename, fileInfo.size_filename+1, NULL, 0, NULL, 0);
		filename[fileInfo.size_filename] = '\0';

		// check if it contains directory
		NSString *strPath = [NSString stringWithUTF8String:filename];
		BOOL isDirectory = NO;
		if(filename[fileInfo.size_filename-1] == '/' || filename[fileInfo.size_filename-1] == '\\') {
			isDirectory = YES;
		}
		free(filename);
		if([strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location != NSNotFound) {
			// contains a path
			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
		}
		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
		if(isDirectory) {
			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		else {
			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		}

		// overwrite?
		if([fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite ) {
			unzCloseCurrentFile(zipFile);
			ret = unzGoToNextFile(zipFile);
			continue;
		}

		// write file
		FILE *fp = fopen((const char*)[fullPath UTF8String], "wb");
		while(fp) {
			read = unzReadCurrentFile(zipFile, buffer, 4096);
			if(read > 0) {
				fwrite(buffer, read, 1, fp );
			}
			else if(read < 0) break;
			else break;
		}
		if(fp) {
			fclose(fp);

			// set the orignal datetime property
			NSDate* orgDate = nil;
			NSDateComponents *dc = [[NSDateComponents alloc] init];
			dc.second = fileInfo.tmu_date.tm_sec;
			dc.minute = fileInfo.tmu_date.tm_min;
			dc.hour = fileInfo.tmu_date.tm_hour;
			dc.day = fileInfo.tmu_date.tm_mday;
			dc.month = fileInfo.tmu_date.tm_mon+1;
			dc.year = fileInfo.tmu_date.tm_year;
			NSCalendar *gregorian = [[NSCalendar alloc]
									 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			orgDate = [gregorian dateFromComponents:dc] ;

			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
			if(attr) {
				[NSFileManager.defaultManager setAttributes:attr ofItemAtPath:fullPath error:nil];
			}
		}
		unzCloseCurrentFile(zipFile);
		ret = unzGoToNextFile(zipFile);
	}
	return success;
}

- (void)close {
	if(zipFile) {
		unzClose(zipFile);
	}
	zipFile = NULL;
}

@end
