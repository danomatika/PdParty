Device Patch Size Templates
===========================

This is a small set of empty patches that are pre-sized to match specific device types and orientations. If you want your patch to be rendered as exact as possible, it's best to work off of these.

Currently, the templates are:

* iPhone-portrait: 568x276 (-44 nav bar height), iPhone 5
* iPhone-landscape: 320x524 (-44 nav bar height), iPhone 5
* iPad-portrait: 384x480  (-64 nav bar height)
* iPad-landscape: 512x352 (-64 nav bar height)

If you need to make the patch larger, simply increase both dimensions by the same amount to keep the correct aspect ratio.

You can open a patch in a text editor and change the dimensions on the first line.

FOr example, the iPad-landscape patch is basically:

    #N canvas 200 200 384 480 10;

The 5th & 6th items in the list are the width & height: 384 & 480. Doubling both of these to 768 & 960 will preserve the aspect ratio.
