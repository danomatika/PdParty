#! /bin/bash
#
# this script automatically updates the sources for the ZipArchive Obj-C library
#
# to upgrade to a new version, change the version number below
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)
destDir=../libs/ZipArchive

###

# move to this scripts dir
cd $WD

# get latest source
git clone https://github.com/mattconnolly/ZipArchive.git

# remove stuff we don't need
rm ZipArchive/minizip/ChangeLogUnzip
rm ZipArchive/minizip/Makefile
rm ZipArchive/minizip/MiniZip64_Changes.txt
rm ZipArchive/minizip/MiniZip64_info.txt
rm ZipArchive/minizip/make_vms.com
rm ZipArchive/minizip/miniunz.c
rm ZipArchive/minizip/minizip.c

# create destination dir
mkdir -pv $destDir

# copy sources
cp -v ZipArchive/ZipArchive/*.h $destDir
cp -v ZipArchive/ZipArchive/*.m $destDir
cp -vR ZipArchive/minizip $destDir

# copy license
cp -v ZipArchive/LICENSE $destDir

# cleanup
rm -rf ZipArchive

