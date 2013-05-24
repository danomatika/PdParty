#! /bin/bash

WD=$(dirname $0)

DESTDIR=../res/patches/lib

###

cd $WD

# get latest source
git clone git://github.com/rjdj/rjlib.git rjlib

# copy input/output patches
mkdir -p $DESTDIR/rj
cp -v rjlib/pd/*.pd $DESTDIR/rj

# copy deprecated rj patches
mkdir -p $DESTDIR/rj_deprecated
cp -Rv rjlib/deprecated/* $DESTDIR/rj_deprecated

# copy rj patches
#cp -Rv rjlib/rj ../bin/data/externals

# copy rj external sources
mkdir -p ../libs/pd/externals/rj
cp -v rjlib/src/*.c ../libs/pd/externals/rj

# cleanup
rm -rf rjlib

