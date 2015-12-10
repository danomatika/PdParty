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
//void httpreceive_setup();
//void httpreq_setup();
void midifile_setup();
//void packOSC_setup();
//void pipelist_setup();
//void routeOSC_setup();
//void tcpclient_setup();
//void tcpreceive_setup();
//void tcpsend_setup();
//void tcpserver_setup();
//void udpreceive_setup();
//void udpreceive_tilde_setup();
//void udpsend_setup();
//void udpsend_tilde_setup();
//void unpackOSC_setup();

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
	//httpreceive_setup();
	//httpreq_setup();
	midifile_setup();
	//packOSC_setup();
	//pipelist_setup();
	//routeOSC_setup();
	//tcpclient_setup();
	//tcpreceive_setup();
	//tcpsend_setup();
	//tcpserver_setup();
	//udpreceive_setup();
	//udpreceive_tilde_setup();
	//udpsend_setup();
	//udpsend_tilde_setup();
	//unpackOSC_setup();
	
	// rj
	rj_accum_setup();
	rj_barkflux_accum_tilde_setup();
	rj_centroid_tilde_setup();
	rj_senergy_tilde_setup();
	rj_zcr_tilde_setup();
}

@end
