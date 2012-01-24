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

	// the number if libpd ticks per buffer,
	// used to compute the audio buffer len: tpb * blocksize (always 64)
	int ticksPerBuffer = 8;	// 8 * 64 = buffer len of 512

	// setup OF sound stream
	ofSoundStreamSetup(2, 2, this, 44100, ofxPd::blockSize()*ticksPerBuffer, 4);

	// setup the app core
	core.setup(2, 2, 44100, ticksPerBuffer);
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
void App::keyPressed(int key) {
	core.keyPressed(key);
}

//--------------------------------------------------------------
void App::mouseMoved(int x, int y) {}

//--------------------------------------------------------------
void App::mouseDragged(int x, int y, int button) {}

//--------------------------------------------------------------
void App::mousePressed(int x, int y, int button) {}

//--------------------------------------------------------------
void App::mouseReleased(int x, int y, int button) {}

//--------------------------------------------------------------
void App::windowResized(int w, int h) {}

//--------------------------------------------------------------
void App::audioReceived(float * input, int bufferSize, int nChannels) {
	core.audioReceived(input, bufferSize, nChannels);
}

//--------------------------------------------------------------
void App::audioRequested(float * output, int bufferSize, int nChannels) {
	core.audioRequested(output, bufferSize, nChannels);
}
