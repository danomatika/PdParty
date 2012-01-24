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
#pragma once

#include "ofMain.h"
#include "Poco/RegularExpression.h"
#include "Poco/StringTokenizer.h"

#include "Types.h"

class PdParser {

	public:
	
		/// print out a particular atom line
		static void printAtom(AtomLine& line) {
			stringstream stream;
			for(int i = 0; i < line.size(); ++i) {
				stream << " [" << line[i] << "]";
			}
			cout << stream.str() << endl;
		}
		
		/// print out all of the atoms found
		static void printAtoms(vector<AtomLine>& atomLines) {
			for(int i = 0; i < atomLines.size(); ++i)
				printAtom(atomLines[i]);
		}

		
		/// read a pd patch into a string
		/// returns an empty string ("") on an error
		static string readPatch(string patch) {
			
			ofLogVerbose() << "PdParser: opening patch: \""
						   << ofFilePath::getFileName(patch) << "\"";
		
			ofFile patchFile;
			if(!patchFile.open(ofFilePath::getAbsolutePath(ofToDataPath(patch)))) {
				ofLogError() << "PdParser: could not open patch: \""
							 << ofFilePath::getFileName(patch) << "\"";
				return "";
			}
			
			return patchFile.readToBuffer().getText();
		}
		
		/// parse a given pd patch text into atom lines
		/// note: clears, does not append to vector
		static void getAtomLines(string patchText, vector<AtomLine>& atomLines) {
			
			atomLines.clear();
			
			// break string into lines
			Poco::RegularExpression pattern(s_line_re, Poco::RegularExpression::RE_MULTILINE);
			Poco::RegularExpression::Match match;
			int offset = 0;
			while(pattern.match(patchText, offset, match) > 0) {
				
				// remove trailing ";\n"
				string subject = patchText.substr(match.offset, match.length-2);
				
				// split line into string delimited by spaces ' '
				AtomLine al;
				Poco::StringTokenizer tokenizer(subject, " ");
				Poco::StringTokenizer::Iterator iter;
				for(iter = tokenizer.begin(); iter != tokenizer.end(); ++iter)
					al.push_back((*iter));
				if(al.size() > 0)
					atomLines.push_back(al);
				
				offset = match.offset+match.length;
			}
			
			ofLogVerbose() << "PdParser: parsed " << atomLines.size() << " atom lines";
		}
		
	private:
	
		static const string s_line_re;
};

const string PdParser::s_line_re = "(#((.|\r|\n)*?)[^\\\\])\r{0,1}\n{0,1};\r{0,1}\n";
