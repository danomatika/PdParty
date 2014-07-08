PdParty
=======

Pure Data patches for iOS

Copyright (c) [Dan Wilcox](danomatika.com) 2011-14

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

See https://github.com/danomatika/PdParty for documentation

DESCRIPTION
-----------

Run your [Pure Data](https://en.wikipedia.org/wiki/Pure_Data) patches on iOS with native GUIs emulated, inspired by Chris McCormick's Android [PdDroidParty](http://mccormick.cx/projects/PdDroidParty/) and the (now defunct) original RjDj app.

<p align="center">
	<img src="http://droidparty.net/PdDroidParty.png"/><br/>
	<small>(Image by PdDroidParty).</small>
</p>

### Are you an alpha/beta tester?

Head on over to the [User Guide](https://github.com/danomatika/PdParty/blob/master/doc/PdParty_User_Guide.md).

### 3rd Party Libraries

This project uses:

* [libpd](https://github.com/libpd/libpd): audio engine
* [PGMidi](https://github.com/petegoodliffe/PGMidi): midi i/o
* [CocoaOSC](https://github.com/danieldickison/CocoaOSC): Open Sound Control i/o
* [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer): WebDAV server
* [ZipArchive](https://code.google.com/p/ziparchive/): support for decompressing zip archives

### 3rd Party Resources

* [DejaVu Sans Mono](http://dejavu-fonts.org/wiki/index.php?title=Main_Page): font
* [Icons8](http://icons8.com): iOS7 icons

### 3rd Party Services

* [Testflight](http://www.testflightapp.com): alpha/beta testing distribution
* [Crashlytics](http://crashlytics.com): automated crash reporting 

INSTALLATION & BUILDING
-----------------------

Open the Xcode project and Build/Run.

You can upgrade to newer versions of the libraries used by the project by running the update scripts in the `scripts` dir which clone the library and copy it's source files into `libs`.

DEVELOPING
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
