#! /bin/bash
#
# updates rjlib sources & abstractions
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)

DESTDIR=../res/patches/lib
CPDIR=../doc/composerpack

###

cd $WD

# get latest source
#git clone git://github.com/rjdj/rjlib.git rjlib
git clone git://github.com/danomatika/rjlib.git rjlib

# copy input/output patches
mkdir -p $DESTDIR/pd
mkdir -p $CPDIR/pd
mkdir -p $CPDIR/templates/DroidTemplate/pd
cp -v rjlib/pd/*.pd $DESTDIR/pd
cp -v rjlib/pd/*.pd $CPDIR/pd
cp -v rjlib/pd/*.pd $CPDIR/templates/DroidTemplate/pd

# copy deprecated rj patches
mkdir -p $DESTDIR/rj_deprecated
cp -Rv rjlib/deprecated/* $DESTDIR/rj_deprecated

# copy rj external sources
mkdir -p ../libs/pd-externals/rj
cp -v rjlib/src/*.c ../libs/pd-externals/rj

# cleanup
rm -rf rjlib
