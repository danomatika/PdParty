/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#include "AppCore.h"

#include "PdParser.h"

//--------------------------------------------------------------
void AppCore::setup(const int numOutChannels, const int numInChannels,
				    const int sampleRate, const int ticksPerBuffer) {

	ofSetFrameRate(60);
	ofSetVerticalSync(true);
	ofSetEscapeQuitsApp(true);
	//ofSetLogLevel(OF_LOG_VERBOSE);
	
	cout << ofFilePath::getCurrentWorkingDirectory() << endl;
	
	if(!pd.init(numOutChannels, numInChannels, sampleRate, ticksPerBuffer)) {
		ofLog(OF_LOG_ERROR, "Could not init pd");
		OF_EXIT_APP(1);
	}
	
	// subscribe to receive source names
	pd.subscribe("toOF");
	pd.subscribe("env");

	// add message receiver
	pd.addReceiver(*this);   // automatically receives from all subscribed sources
	pd.ignore(*this, "env"); // don't receive from "env"
    //pd.ignore(*this);             // ignore all sources
	//pd.receive(*this, "toOF");	// receive only from "toOF"
	
    // add midi receiver
    pd.addMidiReceiver(*this);  // automatically receives from all channels
    //pd.ignoreMidi(*this, 1);     // ignore midi channel 1
    //pd.ignoreMidi(*this);        // ignore all channels
    //pd.receiveMidi(*this, 1);    // receive only from channel 1

	// add the data/pd folder to the search path
	pd.addToSearchPath("pd");

	// audio processing on
	pd.start();

	gui.setSize(ofGetWidth(), ofGetHeight());
	gui.setFont("fonts/Vera.ttf");

	// load gui
	vector<AtomLine> atoms;
	PdParser::getAtomLines(PdParser::readPatch("gui.pd"), atoms);
	PdParser::printAtoms(atoms);
	gui.buildGui(atoms);
	
	pd.openPatch("gui.pd");
}

//--------------------------------------------------------------
void AppCore::update() {
}

//--------------------------------------------------------------
void AppCore::draw() {
	ofBackground(255);
	
	gui.draw();
}

//--------------------------------------------------------------
void AppCore::exit() {
	gui.clear();
}

//--------------------------------------------------------------
void AppCore::keyPressed (int key) {

	switch(key) {
		default:
			break;
	}
}

//--------------------------------------------------------------
void AppCore::audioReceived(float * input, int bufferSize, int nChannels) {
	pd.audioIn(input, bufferSize, nChannels);
}

//--------------------------------------------------------------
void AppCore::audioRequested(float * output, int bufferSize, int nChannels) {
	pd.audioOut(output, bufferSize, nChannels);
}

//--------------------------------------------------------------
void AppCore::print(const std::string& message) {
	cout << message << endl;
}

//--------------------------------------------------------------		
void AppCore::receiveBang(const std::string& dest) {
	cout << "OF: bang " << dest << endl;
}

void AppCore::receiveFloat(const std::string& dest, float value) {
	cout << "OF: float " << dest << ": " << value << endl;
}

void AppCore::receiveSymbol(const std::string& dest, const std::string& symbol) {
	cout << "OF: symbol " << dest << ": " << symbol << endl;
}

void AppCore::receiveList(const std::string& dest, const List& list) {
	cout << "OF: list " << dest << ": ";
	
	// step through the list
	for(int i = 0; i < list.len(); ++i) {
		if(list.isFloat(i))
			cout << list.asFloat(i) << " ";
		else if(list.isSymbol(i))
			cout << list.asSymbol(i) << " ";
	}
    
    // you can also use the built in toString function or simply stream it out
    // cout << list.toString();
    // cout << list;
	
    // print an OSC-style type string
	cout << list.types() << endl;
}

void AppCore::receiveMessage(const std::string& dest, const std::string& msg, const List& list) {
	cout << "OF: message " << dest << ": " << msg << " " << list.toString() << list.types() << endl;
}

//--------------------------------------------------------------
void AppCore::receiveNoteOn(const int channel, const int pitch, const int velocity) {
	cout << "OF MIDI: note on: " << channel << " " << pitch << " " << velocity << endl;
}

void AppCore::receiveControlChange(const int channel, const int controller, const int value) {
	cout << "OF MIDI: control change: " << channel << " " << controller << " " << value << endl;
}

// note: pgm nums are 1-128 to match pd
void AppCore::receiveProgramChange(const int channel, const int value) {
	cout << "OF MIDI: program change: " << channel << " " << value << endl;
}

void AppCore::receivePitchBend(const int channel, const int value) {
	cout << "OF MIDI: pitch bend: " << channel << " " << value << endl;
}

void AppCore::receiveAftertouch(const int channel, const int value) {
	cout << "OF MIDI: aftertouch: " << channel << " " << value << endl;
}

void AppCore::receivePolyAftertouch(const int channel, const int pitch, const int value) {
	cout << "OF MIDI: poly aftertouch: " << channel << " " << pitch << " " << value << endl;
}

// note: pd adds +2 to the port num, so sending to port 3 in pd to [midiout],
//       shows up at port 1 in ofxPd
void AppCore::receiveMidiByte(const int port, const int byte) {
	cout << "OF MIDI: midi byte: " << port << " " << byte << endl;
}
