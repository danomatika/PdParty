PdParty User Guide
==================

Version: **1.4.1**  
Date: 2023-11-14

PdParty is an iOS app that allows you to run [Pure Data](http://puredata.info/) patches on Apple mobile devices using libpd. It is directly inspired by Chris McCormick's [PdDroidParty](http://droidparty.net/) and the original RjDj app by [Reality Jockey](http://rjdj.me/). It takes a step further by supporting OSC and MIDI and by implementing the native Pd gui objects for a WYSIWYG patch -> mobile device experience:

<p align="center">
	This patch in Pure Data...<br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/patch_scene_pd.png"/>
</p>

<p align="center">
	becomes this on iPhone...<br/><br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/patch_scene_iPhone.png" width="300"/>
</p>

<p align="center">
	and this on iPad.<br/><br/>
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/patch_scene_iPad.png" width="500"/>
</p>

Acknowledgments
---------------

* [Miller Puckette](http://msp.ucsd.edu/) and the [Pure Data](http://puredata.info/) community
* [libpd](https://github.com/libpd/libpd): Peter Brinkmann and Rich Eakin
* my long suffering / pillar of support wife [Anika](http://anikahirt.de) for graphic design work (and much more)
* [Reality Jockey](http://rjdj.me/) for proving PD + mobile devices = win
* Chris McCormick for providing the design basis with [PdDroidParty](http://droidparty.net/)
* Frank Barknecht and the rjlib crew for a great vanilla abstraction set

This project has been supported, in part, by:
* The CMU [Frank-Ratchye STUDIO for Creative Inquiry](http://studioforcreativeinquiry.org)
* A visiting professorship at the DU [Emergent Digital Practices Program](https://www.du.edu/ahss/edp/)
* My time at the [ZKM | Hertz-Lab](https://zkm.de/en/about-the-zkm/organisation/hertz-lab)
* A pair of workshops given at the [LEONARDO – Zentrum für Kreativität und Innovation Nürnberg](https://leonardo-zentrum.de)

Table of Contents
-----------------

[TOC]

Background
----------

Dan Wilcox 2016

[_robotcowboy_](http://robotcowboy.com) is the author's ongoing human-computer wearable performance project. Focusing on the embodiment of computational sound, _robotcowboy_ was originally built in 2006-2007 as an [MS thesis project](http://danomatika.com/publications/robotcowboy_thesis_07.pdf) using an industrial wearable computer running GNU/Linux & Pure Data, external stereo USB sound & MIDI interfaces, and various input devices including HID gamepads.

<p align="center">
	<img src="http://farm3.staticflickr.com/2435/3632901050_ec39f575af.jpg"/>
</p>

The original _robotcowboy_ system hardware was gigged often, went on a 2 month tour of the United States in 2008, and lasted until the 2011 Pd Convention in Weimar. Around this time, Apple released the iPad 2 which featured a dual core processor and, most importantly, supported USB audio & MIDI interfaces. Seeking an option for new system hardware, the author began on and off development of an iOS application that could perform all of the tasks required for a live _robotcowboy_ performance: run patches, full duplex stereo audio, MIDI, HID game controller support, & Open Sound Control communication.

With PdParty, the author now has a stable low latency mobile/wearable platform with a touchscreen, accelerometer, WiFi networking, and USB MIDI/audio. Here is a belt-based wearable setup using an iPhone, Camera Connection Kit, powered USB hub, Roland Edirol UA-25 USB audio interface, and a Behringer direct box (the latter two are built in the case on the left):

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/belt_setup.png"/>
</p>

See the [Pure Data 2016 conference paper](http://danomatika.com/publications/pdparty_pdcon_16.pdf) for more details.

App Layout
----------

### TL;DR

There is a root settings screen and a patch/scene browser. Go to your patch and run it. Go back to update settings. Patches/scenes have on screen controls for the input volume, audio processing state (on/off), & recording.

### Start Screen

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/start_screen_iPhone.png" width="300"/><br/>
    <small> Start screen on iPhone</small>
</p>

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/start_screen_iPad.png" width="500"/><br/>
    <small> Start screen on iPad, activate by pressing the "Browser" nav button.</small>
</p>

This is the root of the app and is inspired by [TouchOSC](http://hexler.net/software/touchosc). Here you can launch the Patch Browser or change app settings.

This is also where you can enable the WebDAV server to access the app Documents folder for adding/updating patches.

### Patch Browser

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/documents_browser_iPhone.png" width="300"/>
</p>

This is a simple "drill-down" file browser in the app Documents folder. Stuff in here is sandboxed between app versions. Simply navigate to patches or scene folders to run them. A "Now Playing" nav button will take you back to the Scene View for the currently playing patch/scene.

It only displays folders and supported file types. File type icons represent the supported files & scene folder types & certain scene types include a thumbnail image & author subtitle.

You can delete items by swiping right to show the delete button. Moving, copying, mass deletion, & renaming files/folders is available via the Edit button.

The default layout is:

* **libs**: global abstractions, see the "Libs Folder" section in Patching for PdParty below.
* **recordings**: any recordings made using the Scene View on screen controls end up here, recordings are named using the patch/scene name appended with a timestamp (this will change to something better in the future)
* **samples**: example patches and scenes
* **tests**: internal tests

Feel free to delete samples and tests. The libs folder contains abstractions needed by PdParty. This folder is exposed to allow you to update global abstractions as well as GPL-licensed abstractions which must be user upgradeable. If the libs folder is not found, PdParty falls back to its internal backup copy.

The all folders within the libs folder are automatically added to the PdParty search path so this can also be a location for centralized abstraction libraries.

Note: These default folders can be restored on the Settings screen. So if you accidentally remove everything, you're not out of luck!

### Scene View

Running a patch/scene launches the Scene View:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/patch_scene_iPhone.png" width="300"/>
</p>

Gui elements work similarly to those in the Pure Data gui, except now you have multitouch instead of the 10 foot pole called a mouse pointer. Also, Numberboxes can be incrementally scrolled using two fingers. Empty space is used for touch events if the patch/scene type supports them.

The desired aspect ratio is inferred from the patch canvas size and the Scene View is automatically rotated. Also, the device orientation is locked depending on if the Scene is in portrait or landscape. The exceptions to this are RjDj scenes which are portrait on iPhone & PdDroidParty scenes which are always landscape:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/droidparty_scene_iPad.png" width="600"/>
</p>

On iPad, however, RjDJ scenes can be both portrait or landscape:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/rjdj_scene_rotated_iPad.png" width="600"/>
</p>

#### On Screen Controls

Simple on screen controls inspired by the RjDj app are provided to change the audio input level, enable/disable audio dsp, start/stop recording, switch output between earpiece and speakers (iPhone only), restart the scene.

Patches, DroidParty, & PdParty scenes display these controls in a popover activated by the "Controls" nav bar button:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/patch_scene_controls_iPhone.png" width="300"/>
</p>

RjDj scenes always have a square background with the controls located below.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/rjdj_scene_iPhone.png" width="300"/>
</p>

Optionally, a button to launch a Console view to display Pd prints for the current patch/scene can be added to the Controls popover. Enable to Console view in the PdParty Settings.

On iPhone, the speaker icon is added to allow for switching the audio output between the headset speaker (quiet) and the speaker-phone speakers (loud). This may useful to prevent feedback between input and output in certain scenes. For Rj scenes, this control is added as a switch on the scene's info view.

Double-tap the microphone icon to quickly mute/unmute audio input. _Note: The original unmuted value is not saved when PdParty is closed._

#### Recording Scene

There is also a special scene for playing back recordings (aka .wav files). There is a button for looping the playback and the slider controls the current playback position.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/recording_iPhone.png" width="300"/>
</p>

The cassette background is a placeholder for now. When metadata is added, it may be replaced by the scene icon, etc.

### OSC Server Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/osc_settings_iPhone.png" width="300"/>
</p>

Enable the OSC server and update its send and receive settings: ports, host (destination address), etc. The network IP address of the device itself is shown so you know where to send OSC messages to from another device. The server supports both IPv4 and IPv6.

If you have trouble sending or receiving OSC messages on iOS 14.0+, double check that PdParty has permission to access the local network: Settings->Privacy->Local Network.

#### Multicast

Send via [multicast](https://en.wikipedia.org/wiki/IP_multicast) by setting a multicast group in the Send Host field such as "239.200.200.200"

As of PdParty 1.3.0, receive multicast by setting a multicast group in the Receive Multicast Group field. To disable multicast, clear the field.

Depending upon the LAN setup, multicast messaging may be slower or blocked as compared to unicast. Most large organizations block multicast messages by default, so it is recommended to only use this feature within your own private subnetwork.

_Note: Receiving multicast is currently limited to IPv4 only._

### MIDI Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/midi_settings_iPhone.png" width="300"/>
</p>

Enable CoreMIDI and optionally enable Virtual MIDI ports and/or Network MIDI with a macOS machine. There is also a convenience menu item to launch Bluetooth MIDI device discovery. Inputs & Outputs are refreshed when a MIDI device is connected or disconnected. PdParty supports a maximum of 4 Inputs and 4 Outputs.

As of PdParty 1.2.0, there are two MIDI port modes:

* Single (Simple)
* Multiple

In **Single (Simple) Device Mode**, PdParty automatically connects to all detected MIDI devices. All devices share a single MIDI port aka channels 1-16.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/midi_settings_multi_iPhone.png" width="300"/>
</p>

In **Multiple Device Mode**, PdParty mimics the behavior of the Pure Data desktop application and assigns separate MIDI ports to each device:

* Port 1: channels 1-16
* Port 2: channels 17-32
* Port 3: channels 33-48
* Port 4: channels 49-64

Devices can be reordered to set their port number. When **Multiple Device Mode** is enabled, tap the Edit button and drag the device within the Input or Output table.

### App Settings

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/settings_iPhone.png" width="300"/>
</p>

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/settings2_iPhone.png" width="300"/>
</p>

#### App Behavior

These settings are mainly for live performance reasons where you don't want the device to go to sleep when you're trying to wow your audience. Obviously, keeping the screen on and audio running will drain your battery but in my tests so far it will still last for quite a while.

* Disable lock screen: this disables the lock screen sleep timer and keeps the display on
* Runs in background: allows the app to continue to run when backgrounded as long as audio dsp is on (including when screen is locked and display is off)
* Enable Console: Adds a button to the Controls popover to launch a Console view to display Pd prints for the current patch/scene

#### OSC Event Forwarding

These are useful options for patch creation & debugging. Basically, you can send accelerometer, touch, key\*, and game controller events from the device to your computer while you work on your patch/scene in Pure Data. You can also receive live Pd prints from a running patch/scene in PdParty to make sure everything is working as expected.

The OSC server needs to be enabled and a patch/scene must be running in order for events to be streamed. The easiest option is to run an existing patch or upload an empty one you can run while sending events. Event sending *will not* work unless a patch or scene is being run.

_Note: Most sensor events require the services to be enabled within the patch/scene before any events will be sent. Also, certain scene types do not support all events, please see "Scenes" in "Patching for PdParty" for more info._

\* *requires a USB/Bluetooth keyboard*

#### Audio Latency

This is pretty straight-forward and awesome thanks to CoreAudio. A lower audio latency will give you more responsive audio (nearer to "real time") at the cost of more CPU usage and lower battery life. Higher latencies are good for more simultaneous processing or where realtime response is not as critical (lots of delay, recording only, etc).

By default, the "Choose automatic latency" switch is enabled which tells the app to choose the best latency for your device. If this setting is disabled, you can
set your desired buffer size using the radio buttons and you'll see the approximate latency.

Your mileage may vary depending on the device and the complexity of the patch or scene you're running. If you get audio clicks/dropouts, then you need to either increase the buffer size or decrease the processing complexity of your patch.

#### Copy Default Folders

These buttons allow you to copy the default libs, samples, and test folders into the app Documents folder, just as they were when you first ran PdParty. This is mainly there if you wish to re-copy or update any of the default folders.

Patching for PdParty
--------------------

### TL;DR

PdParty only shows gui objects (numbox, slider, etc) with send or receive names. It does not render your entire patch, so you need to create send and receives through the guis you want to appear on the device when you run your patch/scene.

Download the [**PdParty Composer Pack**](http://danomatika.com/code/pdparty/PdParty_composerpack.zip) which contains the abstractions you need when composing on your computer as well as scene type templates.

Naturally, you can also download the PdParty source and open the test patches & examples to see how this is done: <https://github.com/danomatika/PdParty/tree/master/res/patches>

### Detailed Instructions

*Largely borrowed from [PdDroidParty](http://droidparty.net/)*

1. Create a new Pd patch that will contain your GUI objects like sliders, toggles, numberboxes etc. Place your main patch logic inside a subpatch and use the [soundinput] & [soundoutput] [rjlib objects](https://github.com/rjdj/rjlib/tree/master/pd) in place of [adc~] and [dac~] \(soundoutput is required for the recording controls\).

2. PdParty will scale GUI objects to fit the screen of the device. Your patch should have the rough dimensions of a phone/tablet in portrait or landscape mode (e.g. 3:2 aspect ratio or e.g. 480x320 should usually work well). If it is not exact it, doesn't matter - the GUI elements will be scaled.

3. Numberbox, Sliders, Radios, Toggle, Comment, Bang, Canvas, and VU are currently rendered by PdParty and are feature complete (yes, all the edit commands work!). Widgets which accept SHIFT+drag for fine-tuned editing accept two-finger drag in PdParty. Also, the [PdDroidParty](http://droidparty.net) GUI abstractions are supported.

4. All GUI elements should communicate with the main audio patches using send and receive only. You can usually set send and receive for each GUI by right clicking on the object and choosing 'properties' in Pd. Do not directly connect cables to the GUI elements as they won't work. It helps to keep the GUIs on their own in the main patch and have it include the logic of your patch as an abstraction or subpatch containing senders and receivers for interfacing with GUI elements. This is good patch design practice anyway as it is basically a model-view-controller methodology.

5. Copy the patch and/or its containing directory and any needed abstractions to your iOS device using AirDrop, iTunes File Sharing, via WebDAV over your local network, or through "Open in..." from other apps:

    * **AirDrop/Files app**

        Open Finder on your Mac. Select files/folders you want to send to your iOS device. Press the "Share" button, then AirDrop, and select your iOS device when it appears in the list. It should be nearby, unlocked, on the same Wi-Fi network, and have Bluetooth enabled.

        <p align="center">
          <img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/airdrop_open_with.png" width="300">
        </p>

        You'll be asked what app to use with received files. Pick "Files" and find PdParty in the list of apps. Save your files inside the PdParty folder. The Files app is basically like Finder or Explorer on desktop and allows you to manage files within apps that support it.

        For zip files, the device will ask if you want to open in PdParty. Choosing this option will automatically copy the zip file into the PdParty where you can then unzip it by selecting it in the PdParty file browser.

    * **Finder/iTunes File Sharing**

    	On macOS 10.15 or newer, plug in your iOS device and open a Finder window. Select the device in the sidebar, choose the Files tab, and select PdParty. You should then see the contents of the PdParty Documents dir. You can drag and drop items onto this panel.

        On older versions of macOS, plug in your iOS device and open iTunes. Select the device, choose the App tab, and choose PdParty in the File Sharing section. You should then see the contents of the PdParty Documents dir. You can drag and drop items onto this panel and/or use the "Add..." and "Save to..." buttons.

        *Note: You can only see the top most level in the Documents folder and cannot enter subfolders. Sorry, that is simply how the Finder/iTunes file sharing system currently works. For lots of files: zip a folder, drag the zip into PdParty, then unzip the zip file in the PdParty file browser.*

        <p align="center">
          <img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/finder_file_sharing.png"/>
        </p>

    * **WebDAV**

      1. Enable the WebDAV server on the PdParty start screen on the device and connect to it using a file transfer program or the built in WebDAV support in some operating systems using the address below the WebDAV controls on the Start Screen. If you're using macOS or Linux on a local network, the \*.local address should work, otherwise use the IP address (#.#.#.#). The server supports both IPv4 and IPv6.

            *  **macOS**: Finder can mount WebDAV server folders: Go->Connect to Server... CMD+K. Login as "anonymous" (or anything, really) and leave the password blank:

            <p align="center">
                <img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/finder_connect_to_server.png"/>
            </p>

            * **Linux**: both Nautilus (Gnome) & Konqueror (KDE) support mounting WebDAV folders, also [FileZilla](https://filezilla-project.org) and other file transfer applications should work

            * **Windows**: newer versions of Windows Explorer support connecting to WebDAV folders, type the full address (including http://) into the address bar, also [Cyberduck](http://cyberduck.ch) and [FileZilla](https://filezilla-projects.org) work nicely

      2. When the transfer is complete, navigate to the patch folder and run the patch. Don't forget to turn off the WebDAV server when you're done.

      3. Transfer performance may be low if you are transferring *lots of files*. If you experience this, try zipping the project folder and transferring the zip file. You can then unpack the zip in the PdParty browser by selecting it.

    * **Open in...**

      PdParty registers Pd patch \*.pd files and Zip archives (\*.zip, \*.rjz, \*.pdz) with iOS as supported types. This allows for each of these file types to be opened in PdParty from another application ie. Mail, DropBox, etc. When choosing "Open in..." via the Share button, the file(s) will be copied into the main PdParty Documents folder. Zip archives can then be unpacked by clicking on them in the file browser.

    * **Sharing recordings**

      Sharing recordings or other files created by a patch or scene can be done either through the WebDAV server or the Files app. If connected to the WebDAV server on a desktop computer, files can be copied from the device running PdParty back to the computer. If the Files app is available, files in the PdParty folder can be selected and shared, either to other apps, email, or AirDrop.

### Audio I/O

The audio device PdParty uses for input & output is the current device used by the system. If the device changes (something was plugged-in), PdParty will switch to this new device. There is currently no method for manually selecting audio routing.

Input & output are stereo (2 channel) by default. As of version 1.2.0, PdParty will attempt to use the maximum number of input or output channels supported by the current device, depending whichever is greater. As with desktop Pure Data, any extra input or output channels beyond those used by the current device are ignored. Note that the [soundinput] and [soundoutput] abstractions are stereo only, so you will need to roll your own i/o using [adc~] & [dac~] objects.

As of version 1.3.0, the audio samplerate for non-RjDj scenes is selectable between 48000 (default), 41000, and 96000.

### Scenes

PdParty also supports running "scenes" which are basically folders with a specific layout that are treated as a single entity for encapsulation and have certain event attributes:

* RjDj scenes:
  - a folder that ends in \*.rj that contains a _main.pd patch
  - locked to portrait on iPhone
  - an optional background image named "image.jpg" which must have a square aspect ratio and a min size of 320x320
  - an optional browser icon named "thumb.jpg" and a min size of 55x55, will fall back to "image.jpg" if not found
  - an optional info xml file named "Info.plist" or "info.plist" with the following string keys:
    + _author_
    + _description_
    + _name_
    + _category_
  - requires \#touch, \#accelerate & \#gyro events
  - \#touch positions are normalized from 0-320
  - \#accelerate orientation is rotated to match interface
  - optional sensors accessed by abstractions: [rj\_loc], [rj\_compass], & [rj\_time]
  - does not support game controllers
  - fixed 22050 samplerate
* PdDroidParty scenes
  - a folder that contains a droidparty_main.pd patch
  - locked to landscape
  - an optional background image named "background.png" which should have a landscape aspect ratio
  - an optional font named "font.ttf" or "font-antialiased.ttf"
  - does not require the following events (#accelerate, #touch, or [key]/[keyup]/[keyname])
  - sensors are accessed by the [droidsystem] abstraction
  - does not support game controllers
* PdParty scenes
  - a folder that contains a _main.pd patch
  - portrait or landscape
  - an optional background image named "background.png" or "background.jpg"
  - an optional font named "font.ttf" or "font.otf"
  - an optional browser icon named "thumb.png" or "thumb.jpg" and a min size of 55x55
  - an optional info json file named "info.json" with a dictionary & the following keys:
    + _author_
    + _description_
    + _name_
    + _category_
  - requires all event types
  - \#touch positions are normalized from 0-1, extended touch supported
  - sensors are accessed via receivers: \#gyro, \#loc, \#speed, \#altitude, \#compass, \#magnet, \#motion, & \#time
  - sensors are enabled & updated via control messages to \#pdparty
  - supports game controllers
  - supports setting a background image dynamically

Running a regular .pd patch (a Patch scene) is the same as running a PdParty scene, except for background support.

### Pure Data Compatibility

PdParty is built using libpd and can be compared to Pd-vanilla with the following externals:

* **extra**: bundled Pd-vanilla "extras", ie. [fiddle~], [sigmund~], [bob~], etc
* **ggee**: [getdir], [stripdir]
* **mrpeach**: [midifile]

It is highly recommended that you use a vanilla-based abstraction library like [rjlib](https://github.com/rjdj/rjlib) for expanded functionality.

When patching for PdParty (as with RjDj & PdDroidParty), it is recommended that you work with Pure Data vanilla versions 0.46+. If you are working with Pd-extended, disable all externals in order to help lessen the chance you inadvertently use an object that will not create in PdParty. I actually have separate copies of my Pd settings file, one for desktop development and another for Pd-vanilla/libpd work.

#### expr

[expr], [expr~], & [fexpr~] are included with PdParty. As of Pd versions 0.47+, they are under the BSD license which is compatible with the Apple App Store licensing requirements. This was not the case with earlier versions of Pd/libpd.

#### Key events

[key], [keyup], & [keyname]\* work with an external USB or Bluetooth or keyboard.

\* *[keyup] and [keyname] only supported on iOS 13.4+ as there is no way to receive key release events on earlier iOS versions.*

#### Symbol and List

The symbol and list boxes currently only show their contents and cannot be interacted with.

#### VU Meter

[vu] gui objects do *not* have a sending name in PdParty, so make sure you're patch doesn't rely on passing values through any meters.

#### MIDI

All of the midi objects ([notein], [ctlout], etc) work. Obviously you'll need to have a USB MIDI interface (through a USB hub connected to the Apple Camera Connection Kit) or using Network MIDI and macOS.

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_midi_scene_iPhone.png" width="300"/><br/>
	Midi test Pdparty scene
</p>

### PdDroidParty Compatibility

PdParty currently supports:

* PdDroidParty abstractions:
  - [loadsave]
  - [menubang] buttons are added to the controls popup menu
  - [display]
  - [droidsystem]
    + receive messages: sensors, & openurl (vibrate\* is ignored)
    + send messages: accel, gyro, & magnet
  - [knob] implementation of the moonlib external [mknob]
  - [numberbox]
  - [ribbon]
  - [taplist]
  - [touch]
  - [wordbutton]
* scene folder background.png loading
* scene folder font.ttf & font-antialiased.ttf loading
* special ViewPort canvas to set area of main patch to show

<small>\* doesn't do much as audio has to be off for vibrate to happen on iOS</small>

SVG widget styling support is planned, but not an immediate priority as there is no built-in svg handling on iOS and there doesn't seem to be a standout 3rd party SVG library.

[droidnetclient] & [droidnetreceive] are deprecated in PdDroidParty and therefore not supported. Use [netsend] & [netreceive] instead.

### RjDj Compatibility

PdParty currently supports:

* RjDj abstractions/objects:
  - [rj\_image] implemented internally
  - [rj\_text] implemented internally
  - [rj\_loc]
  - [rj\_compass]
  - [rj\_time]
* RjDj externals:
  - [rj\_accum]
  - [rj\_barkflux\_accum~]
  - [rj\_centroid~]
  - [rj\_senergy~]
  - [rj\_zcr~]
* scene background image.jpg
* scene browser icon thumb.jpg
* scene Info.plist

Currently, scene paging and metadata are not supported.

Testing has been done using the original RjDj composer pack as well as various RjDj scenes including:

* _Eargasm_ by Damian Stewart
* _bouncy_ by Georg Bosch
* _Atsuke_ by Frank Barknecht
* _CanOfBeats_ by Chris McCormick

Also, thanks to Joe White for providing a copy of the RjDj _get\_sensors.pd_ patch by Roman Haefeli, et al. which provided an overview of the extended rj sensor objects.

### Events

PdParty returns the following events:

* **[r \#touch] _eventType_ _id_ _x_ _y_**: touch event (default)
  - _eventType_: symbol "down", "xy" (move), or "up"
  - _id_: persistent touch id
  - _x_: x position, normalized 0-1 except for RjDj scenes which use 0-320
  - _y_: y position, normalized 0-1 except for RjDj scenes which use 0-320
* **[r \#touch] _eventType_ _id_ _x_ _y_ _radius_ _force_**: extended touch event
  - _eventType_: symbol "down", "xy" (move), or "up"
  - _id_: persistent touch id
  - _x_: x position, normalized 0-1
  - _y_: y position, normalized 0-1
  - _radius_: radius in points (pixels)
  - _force_: force into screen, normalized 0-1
* **[r \#stylus] _eventType_ _id_ _x_ _y_ _radius_ _force_ _azimuth_ _elevation_**: extended touch stylus event
  - _eventType_: symbol "down", "xy" (move), or "up"
  - _id_: persistent touch id
  - _x_: x position, normalized 0-1
  - _y_: y position, normalized 0-1
  - _radius_: radius in points (pixels)
  - _force_: force into screen, normalized 0-1
  - _azimuth_: clockwise rotation angle in radians of cap end around tip -> 0 screen +X axis, 90 -Y, 180 -X, 270 +Y
  - _elevation_: elevation angle in radians above screen -> 0 parallel (down), 90 perpendicular (up)
* **[r \#accelerate] _x_ _y_ _z_**: 3 axis accelerometer values in Gs
* **[r \#gyro] _x_ _y_ _z_**: 3 axis gyroscope rotation rate in radians/s
* **[r \#loc] _lat_ _lon_ _accuracy_**: GPS location
  - _lat_: latitude in degrees
  - _lon_: longitude in degrees
  - _accuracy_: lat & lon accuracy in meters; negative values are invalid
* **[r \#speed] _speed_ _course_**: GPS speed & course heading, only sent if \#loc events are enabled
  - _speed_: instantaneous speed in meters per second, negative values are invalid
  - _course_: direction of travel, N is 0 degrees, E is 90, S is 180, etc; negative values are invalid
* **[r \#altitude] _altitude_ _accuracy_**: GPS altitude, only sent if \#loc events are enabled
  - _altitude_: altitude above sea level in meters
  - _accuracy_: altitude accuracy in meters; negative values are invalid
* **[r \#compass] _degrees_**: orientation toward magnetic north with the top of UI at 0 degrees
  - _degrees_: heading toward magnetic north -> 0 N, 90 S, 180 S, 270 E
* **[r \#motion] _eventType_ ...**: processed motion events relative to a reference frame
  - **attitude** _pitch_ _roll_ _yaw_: attitude in radians
  - **rotation** _x_ _y_ _z_: 3 axis rate of rotation in radians/s
  - **gravity** _x_ _y_ _z_: gravity in Gs
  - **user** _x_ _y_ _z_: user-initiated acceleration in Gs (without gravity)
* **[r \#magnet] _x_ _y_ _z_**: 3 axis magnetometer values in microteslas
* **[r \#time]**: timestamp event, see "Timestamps" section"
* **[r \#controller]**: game controller event, see "Game Controllers" section
* **[r \#shake]**: system-detected shake event (aka cancel)

_Note: RjDj scenes receive #touch, #accelerate, & #gyro events by default, DroidParty scenes do not receive any events, PdParty & Patch scenes receive all events. This is mainly for explicit compatibility. Extended RjDj sensor access is made via the [rj\_loc] & [rj\_compass] abstractions._

#### Touch

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_touch_scene_iPhone.png" width="300"/><br/>
	Touch test Pdparty scene
</p>

For compatibility, multi-touch `#touch` events conform to the original RjDj format by default: `eventType id x y`.

Additional controls over touch events are available by sending a message to the internal `#pdparty` receiver:

* **\#pdparty touch extended _value_**: extended touch control
  - _value_: boolean 0-1 to enable/disable extended info
* **\#pdparty touch everywhere _value_**: receive touch events over widgets?
  - _value_: boolean 0-1 to enable/disable touch events over widgets

##### Extended and Stylus

As of PdParty 1.3.0, touch events can be sent with extended information, ex: `eventType id x y radius force`

* radius: touch radius in points (pixels)
* force: touch force into screen, normalized 0-1

Additionally, enabling extended touch also enables separate `#stylus` events for the Apple Pencil (or similar devices supported by the Apple APIs) which include:
* azimuth: rotation angle in degrees of cap end around tip
* elevation: elevation angle in degrees above screen

_Note: Extended touch events and stylus events are separate: finger events go to `#touch` and stylus events go to `#stylus`._

##### Everywhere

By default, touch events over widgets are not sent to `#touch`.

As of PdParty 1.3.0, touch events *everywhere* can be enabled to send when over any widget via `#pdparty touch everywhere 1`. This behavior is similar to `[cyclone/mousestate]` with mode 2 (coordinates within patch). Touches over canvas and comment widgets are always forwarded as they are largely on the patch background.

#### Accelerate, Gyro, Magnet, & Motion

<p align="center">
  <img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_accelerate_scene_iPhone.png" width="300"/><br/>
  Accelerate PdParty test scene
</p>

Reading accelerometer, gyroscope, and/or magnetometer events will affect battery life, so these must be manually started after the scene is loaded by sending messages to the internal #pdparty receiver:

* **\#pdparty _sensor_ _value_**: sensor run control
  - _sensor_: accelerate, gyro, magnet, or motion
  - _value_: boolean 0-1 to start/stop the sensor
* **\#pdparty _sensor_ updates _value_**: sensor automatic update control
  - _value_: boolean to start/stop automatic updates (default on)
* **\#pdparty _sensor_**: request the current sensor values if automatic update is disabled
* **\#pdparty _sensor_ _speed_**: set desired update speed, this setting impacts battery life
  - _sensor_: accelerate, gyro, magnet, or motion
  - _speed_: desired update speed as one of the following strings:
    + slow: 10 Hz, user interface orientation speed
    + normal: 30 Hz, normal movement (default)
    + fast: 60 Hz, suitable for gaming
    + fastest: 100 Hz, maximum firehose
* **\#pdparty accelerate orientation _value_**: rotate accelerometer to match interface orientation?
  - _value_: boolean 0-1 to enable/disable accelerometer orientation

_Note: \#touch & \#accelerate events are automatically started for RjDj scenes for backward compatibility._

The accelerometer, gyroscope, and magnetometer values are instantaneous raw values.

##### Orientation

Sensor orientation is relative to the device in portrait:
* x axis: -left / +right
* y axis: -bottom / +right
* z axis: -back / +front

...except for RjDj scenes where the accelerometer is rotated to match the interface orientation. As of PdParty 1.3.0, acceleromtation rotation is no longer the default for all scene types. Re-enable this behavior by sending `#pdparty accelerate orientation 1`.

##### Motion

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_motion_scene_iPhone.png" width="300"/><br/>
	Motion test Pdparty scene
</p>

Motion events are pre-processed orientation values using the accelerometer, gyroscope, and magnetometer relative to a default reference frame:
* attitude: current orientation in space (pitch, roll, yaw)
* rotation: rotation with gyroscope bias removed
* gravity: gravity acceleration vector
* user: user-initiated acceleration

As [described on NSHipster](https://nshipster.com/cmdevicemotion/), motion event orientation is:
> * pitch is rotation around the X-axis, increasing as the device tilts toward you, decreasing as it tilts away
> * roll is rotation around the Y-axis, decreasing as the device rotates to the left, increasing to the right
> * yaw is rotation around the (vertical) Z-axis, decreasing clockwise, increasing counter-clockwise

The reference frame is set whenever the motion service is started, so for detecting relative motion save the first set of values. These can then be subtracted from newer values for a relative difference, ie. detection when a rotation crosses a certain amount of degrees for use as a trigger. 

#### Loc (GPS) Control

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_locate_scene_iPhone.png" width="300"/><br/>
	Loc test PdParty scene
</p>

Loc events are essentially GPS location events, dependent on your device's sensors for accuracy (WiFi only, cell tower + GPS chip, etc). Additionally, speed & altitude events are generated when the location events are enabled.

Since running the GPS location service will affect battery life in most cases, it must be manually started and configured after the scene is loaded by sending messages to the internal #pdparty receiver:

* **\#pdparty loc _value_**: location service run control
  - _value_: boolean to start/stop the location service
* **\#pdparty loc updates _value_**: location automatic update control
  - _value_: boolean to start/stop automatic updates (default on)
* **\#pdparty loc**: request the current location if automatic updates is disabled
* **\#pdparty loc accuracy _type_**: set desired accuracy, this setting impacts battery life
  - _type_: desired accuracy as one of the following strings:
    + navigation: highest possible accuracy using additional sensors at all times, intended to be used only while the device is plugged in
    + best: highest accuracy on battery (default)
    + 10m: accurate to within 10 meters
    + 100m: accurate to within 100 meters
    + 1km: accurate to the nearest kilometer
    + 3km: accurate to the nearest 3 kilometers
* **\#pdparty loc filter _distance_**: set the distance filter for locate events
  - _distance_: the minimum distance in meters of horizontal movement required before a locate event is generated (default 0), a value of 0 indicates no filtering, negative values are clipped to 0

It usually takes a few seconds to fix your position after enabling the location services.

_Note: Loc events are available in PdParty & Patch scene types by default, while the presence of an [rj\_loc] object enables them in RjDj scenes. These events work best on devices with multiple location sensors (iPhone) and may not work on some devices at all (iPad)._

#### Compass Control

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_heading_scene_iPhone.png" width="300"/><br/>
	Compass test PdParty scene
</p>

A compass event is simply the orientation toward magnetic north with the top of the current UI orientation being at 0 degrees.

Like location events, the tracking the compass requires extra resources so it must be manually started by the scene after it is loaded by sending messages to the internal \#pdparty receiver:

* **\#pdparty compass _value_**: compass service run control
* **\#pdparty compass updates _value_**: compass automatic update control
  - _value_: boolean to start/stop automatic updates (default on)
* **\#pdparty compass**: request the current compass heading if automatic updates is disabled
* **\#pdparty compass filter _degrees_**: the minimum amount of change in degrees required before a compass event is generated (default 1), a value of 0 indicates no filtering, negative values are clipped to 0

_Note: Compass events are only available in PdParty & Patch scene types by default, while the presence of an [rj\_compass] object enables them in RjDj scenes. Events work best on devices with a digital compass (phones) and may not work on some devices at all._

#### Timestamps

Timestamps are sent to the [r \#time] receiver with the following argument format:

* **[r \#time]**: timestamp event
  - _year_: year
  - _month_: month
  - _day_month_: day of the month
  - _day_week_: day of the week
  - _day_year_: day of the year
  - _tz_: deviation from GMT, ex. "-700" is US MT which is 7 hours behind GMT
  - _hour_: hour (in 24 hour format)
  - _min_: minute
  - _sec_: second
  - _msec_: millisecond

_This is the same format that the RjDj [rj\_time] object returns._

Timestamp events must be triggered manually by sending a message to the internal \#pdparty receiver in your patches:

* **\#pdparty time**: generate a timestamp with the current time & day

#### Recording

You can manually trigger recording via sending messages to the internal \#pdparty receiver in your patches:

* **\#pdparty scene _name_**: set the scene/file name for recording
  - _name_: timestamp is prepended & file is saved to the recordings dir
* **\#pdparty scene _name_ _timestamp_**: same as above with additional argument
  - _timestamp_: boolean 0-1 to enable prepending timestamp to file name, format "MM-dd-yyyy_HH-mm-ss_NAME.wav"
* **\#pdparty record _value_**: recording control, also connected to the GUI
  - _value_: boolean to start/stop recording

_Note: Recording will only work if you are using the rjlib [soundoutput] patch instead of [dac~]._

#### Opening a URL

You can launch a web view with a given url via sending a message to \#pdparty:

* **\#pdparty openurl _url title1 title2 ..._**

_url_ can be:

* a full URL path: "http://google.com"
* a relative local file path: "local.html" or "../html/index.html"
* a custom URL scheme to open another app: "maps://...", "twitter://...", etc

_title_ is an open ended list of arguments that will be appended together and used as the navigation bar title, "URL" is used by default when there are no title arguments.

Local files are opened in a slide up web view within PdParty while all others are opened by the system in their respective apps: "http://" & "https://" in Safari, "maps://" in Maps, etc.

On iOS 10.0+, non-local URLs are opened asynchronously.

#### Game Controllers

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_controller_scene_iPhone.png" width="300"/><br/>
	Controller PdParty scene
</p>

Compatible iOS MFi game controllers can be read in PdParty if your device supports them. If the controller uses Bluetooth, enable Bluetooth in your iOS settings and make sure the controller is paired to your device. Currently, iOS limits the number of simultaneous controllers to 4.

Controller events can be read via the [r \#controller] receiver with the following format:

* **[r \#controller] _name_ button _buttonname_ _state_**: button event
  - _name_: game controller name, symbol "gc1", "gc1", "gc2", or "gc3"
  - _buttonname_: symbol "a", "b", "x", "y", "dpleft", "dpright", "dpup", "dpdown", "leftshoulder", "rightshoulder", "lefttrigger", "righttrigger"
  - _state_: boolean 0 or 1
* **[r \#controller] _name_ axis _axisname_ _value_**: axis event
  - _name_: game controller name, symbol "gc1", "gc1", "gc2", or "gc3"
  - _axisname_: symbol "leftx", "lefty", "rightx", or "righty"
  - _value_: -1 to 1 with 0 centered
* **[r \#controller] _name_ pause**: original stateless pause event (iOS 12.0 and earlier, sent as "back" button on iOS 13.0+)
  - _name_: game controller name, symbol "gc1", "gc1", "gc2", or "gc3"
* **[r \#controller] connect _name_**: connect event
  - _name_: game controller name, symbol "gc1", "gc1", "gc2", or "gc3"
* **[r \#controller] disconnect _name_**: disconnect event
  - _name_: game controller name, symbol "gc1", "gc1", "gc2", or "gc3"

There is no direct control over enabling/disabling game controller support. This is handled by scene type detection as RjDj & DroidParty scenes do not use controller events.

Game controller button & axis names are based on the [SDL 2.0 GameController enumerations](http://wiki.libsdl.org/CategoryGameController) where "dpup" refers to digital pad up, "dpleft" refers to digital pad left, etc. This format is compatible with the OSC messages sent by the [joyosc](https://github.com/danomatika/joyosc) desktop HID device to OSC event daemon.

Buttons: "a", "b", "x", "y", "leftshoulder", "lefttrigger", "rightshoulder", "righttrigger", "leftstick", "rightstick", "dpup", "dpdown", "dpleft", "dpright", "back", "guide", "start"

Axes: "leftx", "lefty", "rightx", "righty"

Additional behavior as of PdParty 1.4.0:
* "pause" stateless event used only on iOS 11.0 & 12.0, sent as "back" button on iOS 13.0+
* "leftstick" and "rightstick" thumbstick buttons available on iOS 12.1+
* "back" and "start" buttons available on iOS 13.0+
* "guide" button available on iOS 14.0+

The menu button layout seems to generally follow the Playstation controller design:
~~~
PS3: select -  home  - start
iOS:   menu - [home] - [options] (not all devices have a home or options button)
SDL:   back -  guide - start (PdParty uses this)
~~~

#### OSC

PdParty sends and receives OSC (Open Sound Control) messages internally between the PureData instance and the OSC server:

* **[r \#osc-in]**: incoming OSC messages
* **[s \#osc-out]**: outgoing OSC messages

All of the PdParty events can be streamed over OSC, included Pd prints. The receive addresses are as follows:

* /pdparty/touch
* /pdparty/accelerate
* /pdparty/gyro
* /pdparty/loc
* /pdparty/speed
* /pdparty/altitude
* /pdparty/compass
* /pdparty/magnet
* /pdparty/motion
* /pdparty/time
* /pdparty/controller
* /pdparty/shake
* /pdparty/key
* /pdparty/keyup
* /pdparty/keyname
* /pdparty/print

_Note: The argument number and types are equivalent with their receive counterparts, i.e. /pdparty/touch receives the same data as [r \#touch]._

See `docs/composerpack/osc/osc-event-receiver.pd` in the PdParty source repository for an event receiver you can use while patching & debugging on your computer:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/osc_patch.png"/><br/>
	osc-event-receiver.pd test patch
</p>

Also, try the `tests/osc-test.pd` test patch on your computer with the tests/pdparty/Osc scene on the device for a simple example on two-way communication:

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_osc_scene_iPhone.png" width="300"/><br/>
	OSC test PdParty scene
</p>

_Note: PdParty utilizes the OSC library provided by Pure Data vanilla versions 0.46+, mainly the [oscparse] & [oscformat] objects._

### Libs Folder

PdParty automatically adds any subfolders inside the libs folder in the PdParty Documents root folder to the current search path. Put any abstractions here if you want them to be globally accessible.

Also, this is where the default PdParty libraries are copied when the app is first run. This allows you to update the newer versions of the core lib patches. Be careful, as the rj patches, for instance, are required for running RjDj scenes etc. If you screw up / delete something, you can copy back the original files in the Settings screen.

### PdParty URL Scheme

As of version 1.1.0, PdParty has a custom URL scheme "pdparty://" for opening PdParty from other apps on iOS. The host portion of the URL is used as a message type:

    pdparty://MESSAGE/DATA...

 The following messages are supported:

* pdparty:// - empty, simply opens PdParty
* pdparty://_**open**_/path/... - open a patch, scene, or folder inside the Documents folder

To test, enter the following into the address bar in Safari and hit enter:

    pdparty://

This should open PdParty. To open the `all_pd_guis.pd` test patch in the `tests` folder:

    pdparty://open/tests/all_pd_guis.pd

To open a scene contained in a folder, use the path to the folder itself, not any patches within:

    pdparty://open/samples/pdparty/TriSamp

All URLs with unknown message types are treated as the empty "pdparty://" URL:

    pdparty://hello/world/foo/bar

Further message types may be added in the future.

### ViewPort

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_viewport_scene.png"/><br/>
	Viewport test PdParty scene on desktop
</p>

<p align="center">
	<img src="https://raw.github.com/danomatika/PdParty/master/doc/guide/screenshots/pdparty_viewport_scene_iPhone.png" width="300"/><br/>
	Viewport test PdParty scene, tab 1
</p>

PdParty versions 1.3.0+ support the special ViewPort canvas from DroidParty in patches as well as DroidParty and PdParty scenes. The `pos` and `vis_size` messages send to the canvas with the "ViewPort" receive name are used to set the viewport within the main patch. This allows for segmenting complicated GUIs into separate areas whose large widgets should easier to control with "fat" multitouch fingers.

From the PdDroidParty documentation on <http://droidparty.net>:
~~~
It is possible to map only a part of the main Pd window to the actual device screen, 
by using a specially configured canvas GUI:

- In the main pd window, create a canvas gui (menu Put -> Canvas)

- Make sure the canvas is in the background (select all the objects but the canvas, cut and paste)

- Edit the canvas properties, set the receive name to "ViewPort" and configure its size and position 
    to select the part of the window you want to display on the PdDroidParty screen

- You can dynamically change the viewport by sending "pos" and "vis_size" messages to "ViewPort", 
    so you have visual indication of the portion of the screen that will be displayed on PdDroidParty

The selected viewport area will be rescaled in order to fill the screen of the device.
~~~

See the DroidParty `pure-widgets-demo` sample and the PdParty `ViewPort` test.

As of PdParty 1.4.0+, the ViewPort canvas is *not* drawn in PdParty. This matches behavior in DroidParty. If you need a background color, you will can use additional cnv objects.

### Dynamic Background

PdParty versions 1.4.0+ support setting a background image dynamically in PdParty scenes via sending a message to \#pdparty:

* **\#pdparty background load _path_**: load image and set as background
  - _filename_: path to an image file (PNG, JPG) to set as the background image, path is relative to scene directory
* **\#pdparty background clear**: clear current background

Images are set to fill the available space while keeping the original aspect ratio. To avoid stretching or distortion, try to size them as close to the displayed canvas background on your particular device, ie. device screen size - navigation bar height. The same is true when matching GUI widget position to a background image: size the patch canvas as close to the target device as possible. It's best (and more realistic) to plan for a little extra space here and there as opposed to expecting pixel-perfect accuracy, especially between different device types and screen sizes.

See <https://iosref.com/res> for device screen sizes and subtract the navbar height (currently the following as of Summer 2023):

* iPhone: 44
* iPad: 64

Also see the template generator script's pixel sizes: `doc/composerpack/templates/generate_templates.sh`

### Guided Access (Kiosk Mode)

To run PdParty in a sort of kiosk mode, use Guided Access which is an accessibility feature in iOS/iPadOS:

> Guided Access limits your device to a single app and lets you control which features are available. You can turn on Guided Access when you let a child use your device, or when accidental gestures might distract you.

For an overview and usage, see the Apple doc: http://support.apple.com/kb/HT5509

As of PdParty 1.4.0, the following app-specific options are also available:
* Back Button: enable/disable the left back button to return to the Browser
* Controls Button: enable/disable the right controls button

If both buttons are disabled, when a scene is run in PdParty with Guided Access enabled, the patch view cannot be exited and the on-screen home indicator, notifications, and control center are disabled. If the physical home button and side buttons are inaccessible, such as when the device is enclosed in a security case, the scene can be presented in a public environment, ie. as an art installation.

### Startup Configuration File: config.json

As of PdParty 1.4.0, basic configuration settings can be loaded from a JSON file at startup. This should allow for easier deployment of configrations across multiple devices.

A file named `config.json` or `Config.json` placed in the Documents directory must have a root dictionary and contain any of the following:
* **audio**: dict
  + _mivcolume_: float 0-1, microphone / input volume
* **osc**: dict
  + _enabled_: bool, enable/disable the OSC server
  + **send**: dict
    - _host_: string, IP address or hostname to send to
    - _port_: int, port to send to must be > 1024
  + **receive**: dict
    - _port_: int, port to listen on, must be > 1024
    - _group_: string, multicast group, set "" for none
* **midi**: dict
  + _enabled_: bool, enable/disable MIDI I/O
  + _virtual_: bool, enable/disable PdParty's virtual MIDI ports
  + _network_: bool, enable/disable network MIDI ports
  + _multimode_: bool, enable/disable multiple device mode
* **behavior**: dict
  + _nolockscreen_: bool, disable the device lockscreen while running?
  + _background_: bool, keep running in the background?
  + _console_: bool, enable/disable the console control button
* **startup**: dict
  * _path_: string, relative path to patch or scene directory to open at startup, ex. "tests/all_pd_guis.pd"

_Note: Configuration settings **override** previous defaults on load._

No settings are required, all are optional. An example configuration with all keys can be found with the project source files in `docs/config.json`. A minimal example with a few settings:

```json
{
	"osc": {
		"enabled": true,
		"send": {
			"host": "192.168.100.110",
			"port": 1234
		},
	"startup": {
		"path": "my_cool_patch.pd"
	}
}
```

The file is shown in the PdParty Browser but cannot be edited within PdParty. It can, however, be deleted by swiping left to reveal the delete button. It may be possible to edit the file using a 3rd-party text editor, but this is an exercise left up to the reader.
