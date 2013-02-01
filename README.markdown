PdParty
=======

Pure Data patches for iOS

Copyright (c) [Dan Wilcox](danomatika.com) 2011-13

See https://github.com/danomatika/PdParty for documentation

DESCRIPTION
-----------

Run your Pure Data patches on iOS with native GUIs emulated.

<p align="center">
	<img src="http://droidparty.net/PdDroidParty.png"/><br/>
	<small>(Image by PdDroidParty).</small>
</p>

A port of Chris McCormick's Android [PdDroidParty](http://mccormick.cx/projects/PdDroidParty/) to iOS.

No, this is not "Pd for the iPad". You can run patches but there is not built in editor. That may be a future goal.

NOTE: THIS IS CURRENTLY IN AN ALPHA STAGE AND LIKELY NOT TO WORK JUST YET ... STAY TUNED.

Libraries used:

* [libpd](https://github.com/libpd/libpd): audio engine
* [PGMidi](https://github.com/petegoodliffe/PGMidi): midi i/o
* [Lumberjack](https://github.com/robbiehanson/CocoaLumberjack): logging

INSTALLATION & BUILDING
-----------------------

Open the Xcode project and Build/Run.

You can upgrade to newer versions of the libraries used by the project by running the update scripts in the `scripts` dir which clone the library and copy it's source files into `libs`.

DEVELOPING
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
