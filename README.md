PdParty
=======

Pure Data patches for iOS

Copyright (c) [Dan Wilcox](danomatika.com) 2011-13

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

See https://github.com/danomatika/PdParty for documentation

DESCRIPTION
-----------

Run your Pure Data patches on iOS with native GUIs emulated, inspired by Chris McCormick's Android [PdDroidParty](http://mccormick.cx/projects/PdDroidParty/) and the (now defunt) original RjDj app.

<p align="center">
	<img src="http://droidparty.net/PdDroidParty.png"/><br/>
	<small>(Image by PdDroidParty).</small>
</p>

### DroidParty Compatibility

PdParty will support DroidParty abstractions ([taplist], [menubang], etc). Custom fonts & SVG widgets/styling are planned, but not an immediate priority and will be saved for a later date. Standalone app support is not planned due to the nature of the iOS AppStore.

### RjDj Compatibility

PdParty will initially support RjDj-style scene directories and thumbnails. Images, touch, and accel data access will be added at a later date.

### Status

No, this is not "Pd for the iPad". You can run patches but there is not built in editor. That may be a future goal.

NOTE: THIS IS CURRENTLY IN AN ALPHA STAGE AND LIKELY NOT TO WORK JUST YET ... STAY TUNED.

### 3rd Party Libraries

This project uses:

* [libpd](https://github.com/libpd/libpd): audio engine
* [PGMidi](https://github.com/petegoodliffe/PGMidi): midi i/o
* [Lumberjack](https://github.com/robbiehanson/CocoaLumberjack): logging
* [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer): WebDAV server
* [DejaVu Sans Mono](http://dejavu-fonts.org/wiki/index.php?title=Main_Page): font

INSTALLATION & BUILDING
-----------------------

Open the Xcode project and Build/Run.

You can upgrade to newer versions of the libraries used by the project by running the update scripts in the `scripts` dir which clone the library and copy it's source files into `libs`.

DEVELOPING
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
