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
#import "PdParser.h"

#import "Log.h"

@implementation PdParser

+ (void)printAtomLine:(NSArray *)line {
	NSMutableString *string = [[NSMutableString alloc] init];
	for(int i = 0; i < line.count; ++i) {
		[string appendString:@"["];
		[string appendString:[line objectAtIndex:i]];
		[string appendString:@"] "];
	}
	DDLogVerbose(@"%@", string);
}

+ (void)printAtomLineArray:(NSArray *)atomLines {
	for(int i = 0; i < atomLines.count; ++i) {
		[PdParser printAtomLine:[atomLines objectAtIndex:i]];
	}
}

+ (NSString *)readPatch:(NSString *)patch {
	
	NSString *absPath = patch;
	if(![patch isAbsolutePath]) {
		absPath = [NSString pathWithComponents:[NSArray arrayWithObjects:@"/", [[NSBundle mainBundle] bundlePath], patch, nil]];
	}
	
	// verbose
	DDLogVerbose(@"PdParser: opening patch \"%@\"", [patch lastPathComponent]);

	if(![[NSFileManager defaultManager] isReadableFileAtPath:absPath]) {
		// error
		DDLogError(@"PdParser: can't read patch: \"%@\"", [patch lastPathComponent]);
		return @"";
	}

	NSError *error = NULL;
	NSData* buffer = [NSData dataWithContentsOfFile:absPath options:NSDataReadingUncached error:&error];
	if(!buffer) {
		// error
		DDLogError(@"PdParser: couldn't open patch \"%@\": %@", [patch lastPathComponent], [error localizedFailureReason]);
		return @"";
	}
	
	// convert buffer to string
	return [[NSString alloc] initWithBytes:[buffer bytes]
                                    length:buffer.length
                                  encoding:NSUTF8StringEncoding];
}

// icu regex doc: http://userguide.icu-project.org/strings/regexp
+ (NSArray *)getAtomLines:(NSString *)patchText {
	
	NSMutableArray *atomLines = [[NSMutableArray alloc] init];
	
	// break string into lines
	NSRegularExpression *lineRegexp = [NSRegularExpression regularExpressionWithPattern:@"(#((.|\r|\n)*?)[^\\\\])\r{0,1}\n{0,1};\r{0,1}\n"
																				options:NSRegularExpressionCaseInsensitive
																				  error:NULL];
	NSArray *lineMatches = [lineRegexp matchesInString:patchText options:0 range:NSMakeRange(0, patchText.length)];
	for(NSTextCheckingResult *lineMatch in lineMatches) {
	
		// grab matching line as a string & remove trailing ";\n"
		NSString *line = [patchText substringWithRange:NSMakeRange(lineMatch.range.location, lineMatch.range.length-2)];

		
		// replace whitespace chars with a space
		NSRegularExpression *atomRegexp = [NSRegularExpression regularExpressionWithPattern:@"\t|\r\n?|\n"
																					options:NSRegularExpressionCaseInsensitive
																					  error:NULL];
		NSString *atom = [atomRegexp stringByReplacingMatchesInString:line
															  options:NSMatchingWithTransparentBounds
																range:NSMakeRange(0, line.length)
														 withTemplate:@" "];
		
		// catch Pd 0.46+ variable width length info appended with a comma at the end of float & symbol atoms
		//
		// example:
		//
		//     #X symbolatom 138 49 10 0 0 0 - - send-ame, f 10;
		//     #X floatatom 137 84 5 0 0 0 - - send-name, f 5;
		//
		// The ", f 10" & ", f5" are supplemental so the following regex catches the ", " and appends a space in front so the comma
		// will become a separate string when parsed. This way, we can catch this supplemental information at the end of an atom line
		// with arbitrary length by looking for a "," in the returned atom line array:
		//
		// array: "#X" "symbolatom" "138" "49" "10" "0" "0" "0" "-" "-" "send-name" "," "f" "10"
		// array: "#X" "floatatom"  "137" "84"  "5" "0" "0" "0" "-" "-" "send-name" "," "f" "5"
		//                                                          atom end ^       ^ info start
		//
		// note: the regex will *not* match escaped commas aka "\," so the following will not be broken:
		//
		// #X text 207 218 hello \, world \, foo & bar \,;
		//
		NSRegularExpression *commaRegexp = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\\\),\\s"
																					options:NSRegularExpressionCaseInsensitive
																					  error:NULL];
		atom = [commaRegexp stringByReplacingMatchesInString:atom
													 options:NSMatchingWithTransparentBounds
													   range:NSMakeRange(0, line.length)
												withTemplate:@" , "]; // add preceding space
		
		// break line into strings delimited by spaces
		[atomLines addObject:[atom componentsSeparatedByString:@" "]];
	}
	
	// verbose
	DDLogVerbose(@"PdParser: parsed %lu atom lines", (unsigned long)atomLines.count);
	
	return atomLines;
}

@end
