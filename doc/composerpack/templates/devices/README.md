Device Patch Size Templates
===========================

This is a small set of empty patches that are pre-sized to match specific device types and orientations. If you want your patch to be rendered as exact as possible, it's best to work off of these.

_As PdParty currently relies on the nav bar being shown, the nav bar size is subtracted from the template heights: -44 for iPhone and -64 for iPad._

Currently, the templates are:


* iPhone 5, 5s, SE1
  - iPhone-5-portrait: 320 x 524
  - iPhone-5-landscape: 568 x 276
* iPhone 6, 6s, 7, 8, SE2, SE3
  - iPhone-6-portrait:
  - iPhone-6-landscape:
* iPhone 6+, 6s+, 7+, 8+
  - iPhone-6-plus-portrait:
  - iPhone-6-plus-landscape:
* iPhone
* iPad-portrait: 384 x 480
* iPad-landscape: 512 x 352

If you need to make the patch larger, simply increase both dimensions by the same amount to keep the correct aspect ratio.

You can open a patch in a text editor and change the dimensions on the first line.

For example, the iPad-landscape patch is basically:

    #N canvas 200 200 384 480 10;

The 5th & 6th items in the list are the width & height: 384 & 480. Doubling both of these to 768 & 960 will preserve the aspect ratio.

For a list of device screen sizes, see the Apple developer doc [Displays page](https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html) or external sites such as [iosref.com](https://iosref.com/res). Note: the sizing values used by PdParty are in logical points, not the native resolution.
