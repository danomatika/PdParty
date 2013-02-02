/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/ofxPd for documentation
 *
 */

#import <Foundation/Foundation.h>

@interface PdParser : NSObject
	
// print out a particular atom line with words separated by spaces
+ (void)printAtom:(NSArray *)line;

/// print out all of the atoms found
/// atomLines is an array of atom lines
+ (void)printAtoms:(NSArray *)atomLines;

/// read a pd patch into a string
/// returns an empty string ("") on an error
+ (NSString *)readPatch:(NSString *)patch;

/// parse a given pd patch text into atom lines
+ (NSArray *)getAtomLines:(NSString *)patchText;

@end
