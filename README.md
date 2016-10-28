PdParty
=======

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/images/background/patchview_bg.png"/>
</p>

Copyright (c) [Dan Wilcox](danomatika.com) 2011-16

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

See https://github.com/danomatika/PdParty for documentation

**Want to join the BETA test? Send your name & email address to:**

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/contact.png"/>
</p>

DESCRIPTION
-----------

Run your [Pure Data](https://en.wikipedia.org/wiki/Pure_Data) patches on iOS with native GUIs emulated. Inspired by Chris McCormick's Android [PdDroidParty](http://mccormick.cx/projects/PdDroidParty) and the (now defunct) original RjDj app.

<p align="center">
	<img src="http://droidparty.net/PdDroidParty.png"/><br/>
	<small>(Image by PdDroidParty).</small>
</p>

USER GUIDE & COMPOSER PACK
--------------------------

Are you a beta tester?

Head on over to the [**User Guide**](https://github.com/danomatika/PdParty/blob/master/doc/guide/PdParty_User_Guide.md)

and

Download the [**PdParty Composer Pack**](http://docs.danomatika.com/PdParty_composerpack.zip) which contains the abstractions you need when composing on your computer as well as scene type templates.

ACKNOWLEDGEMENTS
----------------

### 3rd Party Libraries

This project uses:

* [libpd](https://github.com/libpd/libpd): audio engine
* pd externals:
  * _ggee_: getdir, moog~, stripdir
  * _mrpeach_: midifile
  * _rjlib_: rj_accum, rj_barkflux_accum~, rj_centroid~, rj_senergy~, rj_zcr~
* [PGMidi](https://github.com/petegoodliffe/PGMidi): midi i/o
* [liblo](http://liblo.sourceforge.net): Open Sound Control i/o
* [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer): WebDAV server
* [ZipArchive](https://code.google.com/p/ziparchive): support for decompressing zip archives
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD): progress spinner overlay
* [UIAlertView+Blocks](https://github.com/ryanmaxwell/UIAlertView-Blocks)
* [UIActionSheet+Blocks](https://github.com/ryanmaxwell/UIActionSheet-Blocks)

### 3rd Party Samples
* CanOfBeats, multibeat, & pure-widgets-demo: Chris McCormick
* Atsuke: Frank Barknecht
* Eargasm: Damian Stewart
* bouncy: Georg Bosch

### 3rd Party Resources

* [DejaVu Sans Mono](http://dejavu-fonts.org/wiki/Main_Page): font
* [Icons8](http://icons8.com): iOS7+ icons

INSTALLATION & BUILDING
-----------------------

Open the Xcode project and Build/Run.

You can upgrade to newer versions of the libraries used by the project by running the update scripts in the `scripts` dir which clone the library and copy it's source files into `libs`.

DEVELOPING
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
