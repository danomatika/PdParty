#! /bin/bash
#
# this script automatically updates the sources for the MBProgressHUD ios library
#
# to upgrade to a new version, change the version number below
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2012
#

WD=$(dirname $0)
destDir=../libs/MBProgressHUD
srcDir=MBProgressHUD

###

# move to this scripts dir
cd $WD

# get latest source
git clone https://github.com/jdg/MBProgressHUD.git

# create destination dir
mkdir -pv $destDir

# copy readme/license
cp -v $srcDir/README.mdown $destDir
cp -v $srcDir/LICENSE $destDir

# copy sources
cp -v $srcDir/MBProgressHUD.h $destDir
cp -v $srcDir/MBProgressHUD.m $destDir

# cleanup
rm -rf MBProgressHUD

