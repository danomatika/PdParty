PdParty
=======

<p align="center">
	<img src="http://danomatika.com/code/pdparty/patchview_bg.png"/>
</p>

Copyright (c) [Dan Wilcox](danomatika.com) 2011-22

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

<p align="center">
<a href="http://danomatika.com/code/pdparty"><b>PdParty website</b></a> | <a href="https://itunes.apple.com/app/id970528308"><b>PdParty on the App Store</b></a>
</a>

This project has been supported, in part, by:
* The CMU [Frank-Ratchye STUDIO for Creative Inquiry](http://studioforcreativeinquiry.org)
* A visiting professorship at the DU [Emergent Digital Practices Program](https://www.du.edu/ahss/edp/)
* My time at the [ZKM | Hertz-Lab](https://zkm.de/en/about-the-zkm/organisation/hertz-lab)
* A pair of workshops given at the [LEONARDO – Zentrum für Kreativität und Innovation Nürnberg](https://leonardo-zentrum.de)

Description
-----------

Run your [Pure Data](https://en.wikipedia.org/wiki/Pure_Data) patches on iOS with native GUIs emulated. Inspired by Chris McCormick's Android [PdDroidParty](http://mccormick.cx/projects/PdDroidParty) and the (now defunct) original RjDj app.

<p align="center">
	<img src="http://danomatika.com/code/pdparty/PdDroidParty.png"/><br/>
	<small>(Image from PdDroidParty)</small>
</p>

User Guide & Composer Pack
--------------------------

Head on over to the [**User Guide**](http://danomatika.com/code/pdparty/guide)

&

Download the [**PdParty Composer Pack**](http://danomatika.com/code/pdparty/PdParty_composerpack.zip) which contains the abstractions you need when composing on your computer as well as scene type templates.

Beta Testing
------------

PdParty releases are available on the [App Store](https://itunes.apple.com/app/id970528308).

Want to help with BETA testing new prerelease-versions? Send your name & email address to:

<p align="center">
  <img src="https://raw.github.com/danomatika/PdParty/master/doc/contact.png"/>
</p>

Acknowledgments
---------------

### 3rd Party Libraries

This project uses:

* [libpd](https://github.com/libpd/libpd): audio engine
* pd externals:
  * _ggee_: getdir, stripdir, moog~
  * _mrpeach_: midifile
  * _rjlib_: rj_accum, rj_barkflux_accum~, rj_centroid~, rj_senergy~, rj_zcr~
* [liblo](http://liblo.sourceforge.net): Open Sound Control i/o
* [GCDWebServer](https://github.com/swisspol/GCDWebServer): WebDAV server
* [minizip](http://zlib.net): support for decompressing zip archives
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD): progress spinner overlay

### 3rd Party Samples
* CanOfBeats, drummachine, multibeat, & pure-widgets-demo: Chris McCormick
* Atsuke: Frank Barknecht
* Eargasm: Damian Stewart
* bouncy: Georg Bosch
* Elemental - Rain: Tiago Brizolara

### 3rd Party Resources

* [DejaVu Sans Mono](http://dejavu-fonts.org/wiki/Main_Page): font
* [Icons8](http://icons8.com): iOS7+ icons

Checkout & Build
----------------

Clone this repository and checkout it's submodules using git:

    git clone https://github.com/danomatika/PdParty.git
    git submodule update --init --recursive

Open the Xcode project and Build/Run.

You can upgrade to newer versions of the libraries used by the project by running the update scripts in the `scripts` dir which clone the library and copy it's source files into `libs`.

Developing
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
