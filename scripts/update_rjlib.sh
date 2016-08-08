#! /bin/bash
#
# updates rjlib sources & abstractions
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)

DEST_DIR=../res/patches/lib

###

cd $WD

# get latest source
#git clone git://github.com/rjdj/rjlib.git rjlib
git clone git://github.com/danomatika/rjlib.git rjlib

# copy input/output patches
mkdir -p $DEST_DIR/pd
cp -v rjlib/pd/*.pd $DEST_DIR/pd

# copy deprecated rj patches
mkdir -p $DEST_DIR/rj_deprecated
cp -Rv rjlib/deprecated/* $DEST_DIR/rj_deprecated

# copy rj external sources
mkdir -p ../libs/pd-externals/rj
cp -v rjlib/src/*.c ../libs/pd-externals/rj

# cleanup
rm -rf rjlib
