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

#import "Util.h"
#import "Log.h"
#include "m_pd.h" // for binbuf

//#define DEBUG_PARSER

@implementation PdParser

+ (void)printAtomLine:(NSArray *)line {
	NSMutableString *string = [NSMutableString string];
	for(NSString *s in line) {
		[string appendFormat:@"[%@]", s];
		if(![s isEqual:line.lastObject]) {
			[string appendString:@" "];
		}
	}
	LogVerbose(@"%@", string);
}

+ (void)printAtomLineArray:(NSArray *)atomLines {
	for(NSArray *line in atomLines) {
		[PdParser printAtomLine:line];
	}
}

+ (NSString *)readPatch:(NSString *)patch {
	
	NSString *absPath = patch;
	if(![patch isAbsolutePath]) {
		absPath = [NSString pathWithComponents:[NSArray arrayWithObjects:@"/", Util.bundlePath, patch, nil]];
	}
	
	// verbose
	LogVerbose(@"PdParser: opening patch \"%@\"", patch.lastPathComponent);

	if(![NSFileManager.defaultManager isReadableFileAtPath:absPath]) {
		// error
		LogError(@"PdParser: can't read patch: \"%@\"", patch.lastPathComponent);
		return @"";
	}

	NSError *error = NULL;
	NSData *buffer = [NSData dataWithContentsOfFile:absPath options:NSDataReadingUncached error:&error];
	if(!buffer) {
		// error
		LogError(@"PdParser: couldn't open patch \"%@\": %@", patch.lastPathComponent, error.localizedFailureReason);
		return @"";
	}
	
	// convert buffer to string
	return [[NSString alloc] initWithBytes:buffer.bytes
	                                length:buffer.length
	                              encoding:NSUTF8StringEncoding];
}

// icu regex doc: http://userguide.icu-project.org/strings/regexp
+ (NSArray *)getAtomLines:(NSString *)patchText {

	NSMutableArray *atomLines = [NSMutableArray array];
	
	// break string into lines
	NSRegularExpression *lineRegexp =
		[NSRegularExpression regularExpressionWithPattern:@"(#((.|\r|\n)*?)[^\\\\])\r{0,1}\n{0,1};\r{0,1}\n"
		                                          options:NSRegularExpressionCaseInsensitive
		                                            error:NULL];
	NSArray *lineMatches = [lineRegexp matchesInString:patchText options:0 range:NSMakeRange(0, patchText.length)];
	t_binbuf *binbuf = binbuf_new();
	for(NSTextCheckingResult *lineMatch in lineMatches) {
		NSString *line = [patchText substringWithRange:lineMatch.range];

		// parse atom lines using pd's binbuf
		NSMutableArray *atomLine = [NSMutableArray new];
		binbuf_text(binbuf, line.UTF8String, [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
		int argc = binbuf_getnatom(binbuf);
		t_atom *argv = binbuf_getvec(binbuf);
		//binbuf_print(binbuf);
		for(int i = 0; i < argc; i++) {
			t_atom *a = &argv[i];
			switch(a->a_type) {
				case A_FLOAT: // FIXME: convert back to string for now
					[atomLine addObject:[NSString stringWithFormat:@"%g", a->a_w.w_float]];
					break;
				case A_SYMBOL:
					if(strncmp(a->a_w.w_symbol->s_name, ",", MAXPDSTRING) == 0 && atomLine.lastObject) {
						// concat single commas with previous words
						atomLine[atomLine.count-1] = [NSString stringWithFormat:@"%@,", atomLine.lastObject];
					}
					else {
						[atomLine addObject:[NSString stringWithUTF8String:a->a_w.w_symbol->s_name]];
					}
					break;
				case A_COMMA: // separates main list from options afterward
					[atomLine addObject:[NSNull null]];
					break;
				// ignore, shouldn't see these in a file...
				case A_NULL:
				case A_POINTER:
				case A_SEMI:
				case A_DEFFLOAT:
				case A_DEFSYM:
				case A_DOLLAR:
				case A_DOLLSYM:
				case A_GIMME:
				case A_CANT:
				default:
					break;
			}
		}
		[atomLines addObject:atomLine];
		binbuf_clear(binbuf);

		#ifdef DEBUG_PARSER
			NSLog(@"%@", [atomLine componentsJoinedByString:@" "]);
		#endif
/*
		// grab matching line as a string & remove trailing ";\n"
		NSString *line = [patchText substringWithRange:NSMakeRange(lineMatch.range.location, lineMatch.range.length-2)];

		// replace whitespace chars with a space
		NSRegularExpression *atomRegexp =
			[NSRegularExpression regularExpressionWithPattern:@"\t|\r\n?|\n"
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
		NSRegularExpression *commaRegexp
			[NSRegularExpression regularExpressionWithPattern:@"(?<!\\\\),\\s"
			                                          options:NSRegularExpressionCaseInsensitive
			                                            error:NULL];
		atom = [commaRegexp stringByReplacingMatchesInString:atom
		                                             options:NSMatchingWithTransparentBounds
		                                               range:NSMakeRange(0, line.length)
		                                        withTemplate:@" , "]; // add preceding space

		// break line into strings delimited by spaces
		[atomLines addObject:[atom componentsSeparatedByString:@" "]];
*/
	}
	binbuf_free(binbuf);
	
	// verbose
	LogVerbose(@"PdParser: parsed %lu atom lines", (unsigned long)atomLines.count);
	
	return atomLines;
}

@end
