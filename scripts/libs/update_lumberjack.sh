#! /bin/bash
#
# this script automatically updates the sources for the CocoaLumberjack library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2017
#

WD=$(dirname $0)

VER=3.1.0

SRC_DIR=CocoaLumberjack
DEST_DIR=../../libs/CocoaLumberjack

###

cd $WD

# get latest source
git clone https://github.com/CocoaLumberjack/CocoaLumberjack.git --branch $VER --single-branch

# make folder
mkdir -p $DEST_DIR

# remove stuff we don't need
rm -r $SRC_DIR/Classes/CLI
rm -r $SRC_DIR/Classes/Extensions
rm -r $SRC_DIR/Classes/CocoaLumberjack.swift
rm -r $SRC_DIR/Classes/DDLog+LOGV.h
rm -r $SRC_DIR/Classes/DDAbstractDatabaseLogger.*

# copy sources
cp -Rv $SRC_DIR/Classes/* $DEST_DIR/
cp -Rv $SRC_DIR/LICENSE.txt $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
