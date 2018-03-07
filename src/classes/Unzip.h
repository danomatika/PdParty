/*
 * A simple wrapper for minizip, adapted from ZipArchive
 * https://github.com/mattconnolly/ZipArchive.git
 *
 * Copyright (c) 2018 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import <Foundation/Foundation.h>

/// unpack a zip file
@interface Unzip : NSObject

/// open a zip file at a given path,
/// returns YES when opened successfully
- (BOOL)open:(NSString *)path;

/// unzip to a given location,
/// returns YES on success
- (BOOL)unzipTo:(NSString *)path overwrite:(BOOL)overwrite;

/// close an open zip file
- (void)close;

@end
