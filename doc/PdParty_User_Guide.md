PdParty 0.4.1-alpha
===================

Copyright (c) [Dan Wilcox](danomatika.com) 2011-13

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

See https://github.com/danomatika/PdParty for documentation

**This User Guide is a work in progress. Apologies if it is a bit light for now.**

Description
-----------

PdParty is an iOS app that allows you to run [Pure Data](http://puredata.info/) patches on Apple mobile devices using libpd. It is directly inspired by Chris McCormick's [PdDroidParty](http://droidparty.net/) and the original RjDj app by [Reality Jockey](http://rjdj.me/). It takes a step further by supporting OSC and MIDI and by implementing the native Pd gui objects for a WYSIWYG patch -> mobile device experience:

<p align="center">
	This patch in Pure Data …<br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/patch_scene_pd.png"/>
</p>

<p align="center">
	becomes this on iPhone …<br/><br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/patch_scene_iPhone.png"/>
</p>

<p align="center">
	and this on iPad.<br/><br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/patch_scene_iPad.png"/>
</p>

Acknowledgements
----------------

* [Miller Puckette](http://msp.ucsd.edu/) and the [Pure Data](http://puredata.info/) community
* [libpd](https://github.com/libpd/libpd): Peter Brinkmann and Rich Eakin
* my long suffering / pillar of support wife Anika
* [Reality Jockey](http://rjdj.me/) for proving PD + mobile devices = win
* Chris McCormick for providing the design basis with [PdDroidParty](http://droidparty.net/)
* Frank B. and the rjlib crew for a great vanilla abstraction set
* the [CMU School of Art](https://www.cmu.edu/art/) and the [New Hazlett Theater](http://newhazletttheater.org/) for providing the impetus to write this so I can use it for the upcoming [robotcowboy: Onward to Mars](http://robotcowboy.com/onwardtomars/)

Backstory
---------

In 2006-2007, I built a wearable computer based mobile performance system using Linux & Pure Data called [*robotcowboy*](http://robotcowboy.com) as a [MS thesis project](http://danomatika.com/media/projects/s2007/thesis/dwilcox_thesis_arttech_07.pdf):

<p align="center">
	<img src="http://farm3.staticflickr.com/2435/3632901050_ec39f575af.jpg"/>
</p>

Fast forward a few years and the future of ubiquitous, mobile/wearable computational devices I wrote about in my thesis is here so [I decided to adapt this approach to the iPad](http://robotcowboy.com/news/robotcowboy-2-0/) when iOS officially supported MIDI and low latency usb audio. That and the old industrial wearable I was using was giving up the ghost, plus it was time for a computational upgrade. 

Now I have a stable, low latency mobile/wearable platform with a touchscreen, accelerometer, wifi networking, and usb midi/audio. Here's my belt-based wearable setup using an iPad 2, Camera Connection Kit, powered usb hub, Roland Edirol UA-25 bus-powered usb audio interface, and a Behringer direct box (the latter two are built into the green case on the left):

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/belt_setup.jpg"/>
</p>

App Layout
----------

### TL;DR

There's a root settings screen and a patch/scene browser. Go to your patch and run it. Go back to update settings. Patches/scenes have on screen controls for the input volume, audio processing state (on/off), & recording.

### Start Screen

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/start_screen_iPhone.png"/><br/>
<small> Start screen on iPhone</small>
</p>

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/start_screen_iPad.png"/><br/>
<small> Start screen on iPad, activate by pressing the "Patches" nav button.</small>
</p>

This is the root of the app and is inspired by [TouchOSC](http://hexler.net/software/touchosc). Here you can launch the Patch Browser or change app settings.

This is also where you can enable the WebDAV server to access the app's Documents folder for adding/updating patches.

### Patch Browser

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/documents_browser_iPhone.png"/>
</p>

This is a simple "drill-down" file browser in the app's Document's folder. Stuff in here is sandboxed between app versions. Simply navigate to patches or scene folders to run them. A "Now Playing" nav button will take you back to the Scene View for the currently playing patch/scene.

It only displays folders and supported file types. File type icons will be added in the future.

You can delete items by swiping right to show the delete button. Moving, copying, & renaming files/folders may be added in the future.

The default layout is:

* **libs**: global abstractions, see the "Libs Folder" section in Patching for PdParty below.
* **recordings**: any recordings made using the Scene View on screen controls end up here, recordings are named using the patch/scene name appended with a timestamp (this will change to something better in the future)
* **samples**: PdParty example patches and scenes
* **tests**: internal tests

Feel free to delete samples and tests. **Do not delete the libs folder** as the abstractions inside are required. This folder is exposed to allow you to update/upgrade the global abstractions as well as satisfy the user upgradeability requirement for GPL licensed abstractions.

These default folders can be restored on the Settings screen.

### Scene View

Running a patch/scene launches the Scene View:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/patch_scene_iPhone.png"/>
</p>

Gui elements work similarly to those in the Pure Data gui, except now you have multitouch instead of the 10 foot pole called a mouse pointer. Also, Numberboxes can be incrementally scrolled using two fingers. Empty space is used for touch events if the patch/scene type supports them.

The desired aspect ratio is inferred from the patch canvas size and the Scene View is automatically rotated. Also, the device orientation is locked depending on if the Scene is in portrait or landscape. The exceptions to this are PdDroidParty scenes which are always landscape:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/droidparty_scene_iPad.png"/>
</p>

and RjDJ scenes which support any orientation on iPad:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/rjdj_scene_rotated_iPad.png"/>
</p>

#### On Screen Controls

Simple on screen controls inspired by the RjDj app are provided to change the audio input level, enable/disable audio dsp, and start/stop recording.

Patches, DroidParty, & PdParty scenes display these controls in a popover activated by the "Controls" nav bar button:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/patch_scene_controls_iPhone.png"/>
</p>

RjDj scenes always have a square background with the controls located below.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/rjdj_scene_iPhone.png"/>
</p>

#### Recording Scene

There is also a special scene for playing back recordings (aka .wav files). The slider now controls the playback volume and there is also a button for looping the playback.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/recording_iPhone.png"/>
</p>

The cassette background is a placeholder for now. When metadata is added, it will be replaced by the scene icon, etc.

### OSC Server Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/osc_settings_iPhone.png"/>
</p>

Enable the OSC server here and update it's settings: ports, host (destination address), etc. The Local IP Address is the network IP of the device itself so you know where to send OSC messages to from another device.

### MIDI Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/midi_settings_iPhone.png"/>
</p>

Enable CoreMIDI here and optionally enable Network MIDI with a Mac OSX machine.

Inputs & Outputs are refreshed when a MIDI device is plugged in/out. Currently, PdParty automatically connects to all detected MIDI devices.

### App Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/settings_iPhone.png"/>
</p>

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/settings2_iPhone.png"/>
</p>

#### App Behavior

These settings are mainly for live performance reasons where you don't want the device to go to sleep when you're trying to wow your audience. Obviously, keeping the screen on and audio running will drain your battery but in my tests so far it will still last for quite a while.

* Disable lock screen: this disables the lock screen sleep timer and keeps the display on
* Runs in background: allows the app to continue to run when backgrounded as long as audio dsp is on (including when screen is locked and display is off)

#### OSC Event Forwarding

These are useful options for patch creation & debugging. Basically, you can send accelerometer, touch, and key\* events from the device to your computer while you work on your patch/scene in Pure Data. You can also receive live Pd prints from a running patch/scene in PdParty to make sure everything is working as expected.

The OSC server needs to be enabled and a patch/scene must be running in order for events to be streamed.

\* *requires a usb/bluetooth keyboard*

#### Audio Latency

This is pretty straight forward and awesome thanks to CoreAudio. Simply set your desired buffer size and you'll see the approximate latency. A lower latency will give you more responsive audio (nearer to "real time") at the cost of more CPU usage and lower battery life. Higher latencies are good for more simultaneous processing or where realtime response is not as critical (lots of delay, recording only, etc).

Your mileage may vary depending on the device and the complexity of the patch or scene you're running. If you get audio clicks/audio dropouts, then you need to either increase the buffer size or decrease the processing complexity of your patch.

#### Copy Default Folders

These buttons simply allow you to copy the default libs, samples, and test folders into the app's Document's folder, just as they were when you first ran PdParty. This is mainly there for when you screw up and delete something you probably shouldn't have (libs).

Patching for PdParty
--------------------

*Instructions largely borrowed from [PdDroidParty](http://droidparty.net/)*

1. Create a new Pd patch that will contain your GUI objects like sliders, toggles, numberboxes etc. Place your main patch logic inside a subpatch and use the [soundinput] & [soundoutput] [rjlib objects](https://github.com/rjdj/rjlib/tree/master/pd) in place of [adc~] and [dac] (these are required for the on screen volume and recording controls).

2. PdParty will scale GUI objects to fit the screen of the device. Your patch should have the rough dimensions of a phone/tablet in landscape mode (e.g. 3:2 aspect ratio or e.g. 480x320 should usually work well). If it's not exact it doesn't matter - the GUI elements will be scaled.

3. Numberbox, Sliders, Radios, Toggle, Comment, Bang, Canvas, and VU are currently rendered by PdParty and are feature complete (yes, all the edit commands work!). Also, the [PdDroidParty](http://droidparty.net/) Wordbutton, Taplist, Touch, & Numberbox are supported.

4. All GUI elements should communicate with the main audio patches using send and receive only. You can usually set send and receive for each GUI by right clicking on the object and choosing 'properties' in Pd. Do not directly connect cables to the GUI elements as they won't work. It helps to keep the GUIs on their own in the main patch and have it include the logic of your patch as an abstraction or subpatch containing senders and receivers for interfacing with GUI elements. This is good patch design practice anyway as it is basically a model-view-controller methodology.

5. Copy the patch and/or it's containing directory and any needed abstractions to your iOS device using HTTP over your local network. Enable the WebDAV server on the PdParty start screen on the device and connect to it using a file transfer program or the built in WebDAV support in some operating systems\*.
 
6. When the transfer is complete, navigate to the patch folder and run the patch. Don't forget to turn off the WebDAV server when you're done.

\* for instance, the Mac OSX Finder can mount WebDAV server folders: Go->Connect to Server… CMD+K:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/finder_connect_to_server.png"/>
</p>

### Scenes

PdParty also supports running "scenes" which are basically folders with a specific layout that are treated as a single entity for encapsulation and have certain event attributes:

* RjDj scenes:
  * a folder that ends in *.rj that contains a _main.pd
  * an optional background Image.jpg which must have a square aspect ratio
  * requires only #accelerate & #touch events
* PdDroidParty scenes
  * a folder that contains a droidparty_main.pd
  * locked to landscape
  * does not require any events (#accelerate, #touch, or [key])
* PdParty scenes
  * a folder that contains a _main.pd
  * requires all event types

### Pure Data Compatibility

PdParty is built using libpd and can be compared to Pd-vanilla. It also includes the mrpeach midifile, OSC, & UDP externals.

It's highly recommended that you use a vanilla-based abstraction library like [rjlib](https://github.com/rjdj/rjlib) for expanded functionality.

When patching for PdParty (as with RjDj & PdDroidParty), it is recommended to disable all external libraries except for mrpeach if you are using pd-extended. This should help lessen the chance you inadvertently use an object that will not create in PdParty. I actually have separate copies of my PD settings file, one for desktop development and another for pd-vanilla/libpd work.

#### [expr] & [expr~]

Currently, [expr] and [expr~] are not included with PdParty since they are licensed under the GPL, which is incompatible for linked libraries with the Apple AppStore licensing. There's some confusion as to what license the sources use (the license in the source headers are different to the license in the source dir), if that is cleared up then I'd be happy to add them.

#### Key events

[key] works with an external bluetooth or usb keyboard. [keyup] & [keyname] are not supported as there is currently no *official* way to intercept raw key events on iOS.

#### VU Meter

[vu] gui objects do *not* have a sending name in PdParty, so make sure you're patch doesn't rely on passing values through any meters.

#### MIDI

All of the midi objects ([notein], [ctlout], etc) work. Obviously you'll need to have a usb MIDI interface (through a USB hub connected to the Apple Camera Connection Kit) or using Network MIDI and Mac OSX.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/pdparty_midi_scene_iPad.png"/><br/>
	Midi test Pdparty scene
</p>

### PdDroidParty Compatibility

PdParty currently supports the following PdDroidParty abstractions: [numberbox], [wordbutton], [taplist], & [touch]. More advanced abstractions ([loadsave]. [menubang], etc may be added in the future. Custom fonts & SVG widgets/styling are planned, but not an immediate priority and will be saved for a later date. Standalone app support is not planned due to the nature of the iOS AppStore.

### RjDj Compatibility

PdParty support RjDj-style scene directories, backgrounds, and the [rj_image] and [rj_text] objects. The rj externals ([rj_accum], [rj_barkflux_accum~], [rj_centroid~], [rj_senergy~], & [rj_zcr~]) are also included. Currently, scene paging and metadata are not supported.

### Events

PdParty returns the following events:

* **[r #touch] _eventType_ _id_ _x_ _y_**: multitouch touch event
  * _eventType_: symbol "down", "xy" (move), or "up"
  * _id_: persistent touch id
  * _x_: x position
  * _y_: y position
* **[r #accelerate] _x_ _y_ _z_**: 3 axis accelerometer values in Gs

#### OSC

PdParty sends and receives OSC messages internally between the PureData instance and the OSC server:
 
* **[r #osc-in]**: incoming OSC messages
* **[s #osc-out]**: outgoing OSC messages

Also, most of these events can also be streamed over OSC, included Pd prints. The receive addresses 

* /pdparty/touch
* /pdparty/accelrate
* /pdparty/key
* /pdparty/print

See tests/osc.pd for an example:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/osc_patch.png"/><br/>
	osc.pd test patch
</p>

Also, try this with the tests/pdparty/Osc scene on the device:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/screenshots/pdparty_osc_scene_iPhone.png"/><br/>
	OSC test PdParty scene
</p>

### Libs Folder

PdParty automatically adds any subfolders inside the libs folder in the PdParty Documents root folder to the current search path. Put any abstractions here if you want them to be globally accessible.

Also, this is where the default PdParty libraries are copied when the app is first run. This allows you to update the newer versions of the core lib patches. Be careful, as the rj patches, for instance, are required for running RjDj scenes etc. If you screw up / delete something, you can copy back the original files in the Settings screen.

TODOs
-----

* icons and all that jazz
* full screen / nav bar hiding
* paging and/or TouchOSC style page buttons
* add RjDj metadata support (plist, etc)
* WebDAV is slow when transferring lots of files. zip transfers should be supported …
* Allow alternate styling for gui elements (i.e. TouchOSC)
* add support for more advanced PdDroidParty objects [loadsave], [menubang], etc

Happy Patching!
===============