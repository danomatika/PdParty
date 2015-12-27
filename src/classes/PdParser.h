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
#import <Foundation/Foundation.h>

@interface PdParser : NSObject
	
// print out a particular atom line with words separated by spaces
+ (void)printAtomLine:(NSArray *)line;

/// print out all of the atoms found
/// atomLines is an array of atom lines
+ (void)printAtomLineArray:(NSArray *)atomLines;

/// read a pd patch into a string
/// returns an empty string ("") on an error
+ (NSString *)readPatch:(NSString *)patch;

/// parse a given pd patch text into an array of atom lines
///
/// note: Pd 0.46+ includes variable width obj infomation appended at the end of
/// atom lines as ", f #" with # being the width
///
/// example: #X floatatom 137 84 5 0 0 0 - - send-name, f 5;
///
/// this section is separated from the preceding atom infomation with an
/// unescaped comma: ","
///
+ (NSArray *)getAtomLines:(NSString *)patchText;

@end
