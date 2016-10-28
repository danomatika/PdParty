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
#import "Externals.h"

// explicit declarations

// ggee
void getdir_setup();
void moog_tilde_setup();
void stripdir_setup();

// mrpeach
void midifile_setup();

// rj
void rj_accum_setup();
void rj_barkflux_accum_tilde_setup();
void rj_centroid_tilde_setup();
void rj_senergy_tilde_setup();
void rj_zcr_tilde_setup();

@implementation Externals

+ (void)setup {
	
	// ggee
	getdir_setup();
	moog_tilde_setup();
	stripdir_setup();

	// mrpeach
	midifile_setup();
	
	// rj
	rj_accum_setup();
	rj_barkflux_accum_tilde_setup();
	rj_centroid_tilde_setup();
	rj_senergy_tilde_setup();
	rj_zcr_tilde_setup();
}

@end
