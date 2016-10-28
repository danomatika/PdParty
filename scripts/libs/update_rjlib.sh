#! /bin/bash
#
# updates rjlib sources & abstractions
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)
SRC_DIR=rjlib
DEST_DIR=../../res/patches/lib
EXT_DIR=../../libs/pd-externals/rj/

###

cd $WD

# get latest source
#git clone git://github.com/rjdj/rjlib.git rjlib
git clone git://github.com/danomatika/rjlib.git rjlib

# remove stuff we don't need
rm $SRC_DIR/deprecated/hilbert~.pd

# copy input/output patches
mkdir -p $DEST_DIR/pd
cp -v $SRC_DIR/pd/*.pd $DEST_DIR/pd/

# copy deprecated rj patches
mkdir -p $DEST_DIR/rj_deprecated
cp -Rv $SRC_DIR/deprecated/* $DEST_DIR/rj_deprecated/

# copy rj external sources
mkdir -p $EXT_DIR
cp -v $SRC_DIR/src/*.c $EXT_DIR/

# cleanup
rm -rf $SRC_DIR
