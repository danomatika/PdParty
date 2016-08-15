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
SRC_DIR=ZipArchive
DEST_DIR=../../libs/ZipArchive

###

# move to this scripts dir
cd $WD

# get latest source
git clone https://github.com/mattconnolly/ZipArchive.git

# remove stuff we don't need
rm $SRC_DIR/minizip/ChangeLogUnzip
rm $SRC_DIR/minizip/Makefile
rm $SRC_DIR/minizip/MiniZip64_Changes.txt
rm $SRC_DIR/minizip/MiniZip64_info.txt
rm $SRC_DIR/minizip/make_vms.com
rm $SRC_DIR/minizip/miniunz.c
rm $SRC_DIR/minizip/minizip.c

# create destination dir
mkdir -pv $DEST_DIR

# copy sources
cp -v $SRC_DIR/ZipArchive/*.h $DEST_DIR/
cp -v $SRC_DIR/ZipArchive/*.m $DEST_DIR/
cp -vR $SRC_DIR/minizip $DEST_DIR/

# copy license
cp -v $SRC_DIR/LICENSE $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
