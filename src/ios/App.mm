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
#include "App.h"

//--------------------------------------------------------------
void App::setup() {

	cout << ofFilePath::getCurrentWorkingDirectory() << endl;
	//ofSetDataPathRoot("Resources/data");
	cout << ofFilePath::getCurrentWorkingDirectory() << endl;

	// register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	// iPhoneAlerts will be sent to this
	ofxiPhoneAlerts.addListener(this);
	
	// if you want a landscape orientation 
	// ofxiPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
	
	ofBackground(127, 127, 127);
	
	// the number if libpd ticks per buffer,
	// used to compute the audio buffer len: tpb * blocksize (always 64)
	int ticksPerBuffer = 8;	// 8 * 64 = buffer len of 512
	
	// setup the app core
	core.setup(2, 1, 44100, ticksPerBuffer);

	// setup OF sound stream
	ofSoundStreamSetup(2, 1, this, 44100, ofxPd::blockSize()*ticksPerBuffer, 3);
}

//--------------------------------------------------------------
void App::update() {
	core.update();
}

//--------------------------------------------------------------
void App::draw() {
	core.draw();
}

//--------------------------------------------------------------
void App::exit() {
	core.exit();
}

//--------------------------------------------------------------
void App::touchDown(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void App::touchMoved(ofTouchEventArgs &touch) {

}

//--------------------------------------------------------------
void App::touchUp(ofTouchEventArgs &touch) {

}

//--------------------------------------------------------------
void App::touchDoubleTap(ofTouchEventArgs &touch) {

}

//--------------------------------------------------------------
void App::lostFocus() {

}

//--------------------------------------------------------------
void App::gotFocus() {

}

//--------------------------------------------------------------
void App::gotMemoryWarning() {

}

//--------------------------------------------------------------
void App::deviceOrientationChanged(int newOrientation) {

}

//--------------------------------------------------------------
void App::touchCancelled(ofTouchEventArgs& args) {

}

//--------------------------------------------------------------
void App::audioReceived(float * input, int bufferSize, int nChannels) {
	core.audioReceived(input, bufferSize, nChannels);
}

void App::audioRequested(float * output, int bufferSize, int nChannels) {
	core.audioRequested(output, bufferSize, nChannels);
}
