//
//  AppDelegate.m
//  PdParty
//
//  Created by Dan Wilcox on 1/11/13.
//  Copyright (c) 2013 Dan Wilcox. All rights reserved.
//

#import "PdParser.h"

#import "Log.h"

@implementation PdParser

+ (void)printAtom:(NSArray *)line {
	NSMutableString *string = [[NSMutableString alloc] init];
	for(int i = 0; i < line.count; ++i) {
		[string appendString:@"["];
		[string appendString:[line objectAtIndex:i]];
		[string appendString:@"] "];
	}
	DDLogInfo(@"%@", string);
}

+ (void)printAtoms:(NSArray *)atomLines {
	for(int i = 0; i < atomLines.count; ++i) {
		[PdParser printAtom:[atomLines objectAtIndex:i]];
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

		
		// replace whitespace chars with a space, break line into atoms delimited by spaces
		NSRegularExpression *atomRegexp = [NSRegularExpression regularExpressionWithPattern:@"\t|\r\n?|\n"
																					options:NSRegularExpressionCaseInsensitive
																					  error:NULL];
		NSString *atom = [atomRegexp stringByReplacingMatchesInString:line
															  options:NSMatchingWithTransparentBounds
																range:NSMakeRange(0, line.length)
														 withTemplate:@" "];
		[atomLines addObject:[atom componentsSeparatedByString:@" "]];
	}
	
	// verbose
	DDLogVerbose(@"PdParser: parsed %d atom lines", atomLines.count);
	
	return atomLines;
}

@end
