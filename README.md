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

### Pure Data Compatibility

PdParty is built using libpd and can be compared to Pd-vanilla.

#### [expr] & [expr~]

Currently, [expr] and [expr~] are not included with PdParty since they are licensed under the GPL, which is incompatible for linked libraries with the Apple AppStore licensing. Sorry, complain to Apple.

#### Key events

[key] works with an external bluetooth or usb keyboard. [keyup] & [keyname] are not supported as there is currently no *official* way to intercept raw key events on iOS.

#### VU Meter

[vu] gui objects do *not* have a sending name in PdParty, so make sure you're patch doesn't rely on passing values through any meters.

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

Usage
-----

### Events

PdParty returns the following events:

* **[#touch] _eventType_ _id_ _x_ _y_**: multitouch touch event
  * _eventType_: symbol "down", "xy" (move), or "up"
  * _id_: persistent touch id
  * _x_: x position
  * _y_: y position
* **[#accelerate] _x_ _y_ _z_**: 3 axis accelerometer values in Gs 
* **[#rotate] _degrees_ _orientation_**: device screen rotation
  * _degrees_: rotation amount in degrees: 90, -90, 180, etc
  * _orientation_: symbol "portrait", "upsidedown", "landleft", or "landright"

DEVELOPING
----------

You can help develop PDParty on GitHub: [https://github.com/danomatika/PdParty](https://github.com/danomatika/PdParty)

Create an account, clone or fork the repo, then request a push/merge.

If you find any bugs or suggestions please log them to GitHub as well.
