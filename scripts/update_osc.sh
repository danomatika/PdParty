#! /bin/bash
#
# this script automatically updates the sources for the CocoaOSC ios library
#
# to upgrade to a new version, change the version number below
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# 2013 Dan Wilcox <danomatika@gmail.com> 
#

WD=$(dirname $0)
destDir=../libs/CocoaOSC

###

# move to this scripts dir
cd $WD

# get latest source
git clone git://github.com/danieldickison/CocoaOSC.git

# create destination dir
mkdir -pv $destDir

# don't need another CocoaAsyncSocket copy
rm -rf CocoaOSC/lib/CocoaAsyncSocket

# don't need lib examples
rm -rf Cocoa/lib/RegexKitLite/examples

# copy sources
cp -v CocoaOSC/CocoaOSC/*.h $destDir
cp -v CocoaOSC/CocoaOSC/*.m $destDir
cp -vR CocoaOSC/lib/* $destDir

# copy license
cp -v CocoaOSC/README.md $destDir

# cleanup
rm -rf CocoaOSC

