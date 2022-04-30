#! /bin/sh
#
# this script automatically updates the sources for the minizip C library
#
# to upgrade to a new version, change the version number below
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2016, 2018
#

# stop on error
set -e

VER=v1.2.12

SRC_DIR=zlib
DEST_DIR=../../libs/minizip

###

# move to this scripts dir
cd $(dirname $0)

# get latest source
git clone https://github.com/madler/zlib.git --branch $VER --depth 1

# remove stuff we don't need
rm $SRC_DIR/contrib/minizip/Makefile
rm $SRC_DIR/contrib/minizip/Makefile.am
rm $SRC_DIR/contrib/minizip/MiniZip64_Changes.txt
rm $SRC_DIR/contrib/minizip/MiniZip64_info.txt
rm $SRC_DIR/contrib/minizip/configure.ac
rm $SRC_DIR/contrib/minizip/iowin32.h
rm $SRC_DIR/contrib/minizip/iowin32.c
rm $SRC_DIR/contrib/minizip/make_vms.com
rm $SRC_DIR/contrib/minizip/miniunz.c
rm $SRC_DIR/contrib/minizip/miniunzip.1
rm $SRC_DIR/contrib/minizip/minizip.1
rm $SRC_DIR/contrib/minizip/minizip.c
rm $SRC_DIR/contrib/minizip/minizip.pc.in

# create destination dir
mkdir -pv $DEST_DIR

# copy sources
cp -v $SRC_DIR/contrib/minizip/* $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
