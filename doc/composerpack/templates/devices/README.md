Device Patch Size Templates
===========================

This is a small set of empty patches that are pre-sized to match specific device types and orientations. If you want your patch to be rendered as exact as possible, it's best to work off of these.

The current templates are named in order of device release following the conventions on [iosref.com](https://iosref.com/res):

iPhone
* iphone-13-pro-max: 13 Pro Max, 12 Pro Max
* iphone-13-pro:     13 / Pro, 12 / 12 Pro
* iphone-13-mini:    13 mini, 12 mini
* iphone-11-pro-max: 11 Pro Max, XS Max
* iphone-11-pro:     11 Pro, XS, X
* iphone-11:         11, XR
* iphone-8-plus:     8+, 7+, 6s+, ^+
* iphone-se3:        SE (gen 3), SE (gen 2), 8, 7, 6s, 6
* iphone-se1:        SE (gen 1), 5s, 5c, 5

iPad
* ipad-pro5:  Pro 12.9" (gen 5) - Pro 12.9" (gen 1)
* ipad-pro3:  Pro 11" (gen 3) - Pro 11" (gen1) 
* ipad-air5:  Air (gen 5), Air (gen 4)
* ipad-9:     iPad (gen 9), iPad (gen 8), iPad (gen 7)
* ipad-mini6: mini (gen 6)
* ipad-air3:  Air (gen 3), Pro 10.5"
* ipad-6:     iPad (gen 6), iPad (gen 5), Pro 9.7", Air 2, Air (gen 1), iPad 4, iPad (gen 3)
* ipad-mini5: mini (gen 5), mini 4, mini 3, mini 2, mini (gen 1), iPad (gen 1), iPad (gen 1)

If you need to make the patch larger, simply increase both dimensions by the same amount to keep the correct aspect ratio.

You can open a patch in a text editor and change the dimensions on the first line.

For example, the ipad-6-landscape patch is basically:

    #N canvas 200 200 384 448 10;

The 5th & 6th items in the list are the width & height: 384 & 448. Doubling both of these to 768 & 896 will preserve the aspect ratio.

For a list of device screen sizes, see the Apple developer doc [Displays page](https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html) or external sites such as [iosref.com](https://iosref.com/res). Note: the sizing values used by PdParty are in logical points, not the native resolution.
