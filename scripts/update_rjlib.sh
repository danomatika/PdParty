#! /bin/bash
#
# updates rjlib sources & abstractions
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)

DESTDIR=../res/patches/lib
CPDIR=../pdparty-composer-pack

###

cd $WD

# get latest source
#git clone git://github.com/rjdj/rjlib.git rjlib
git clone git://github.com/danomatika/rjlib.git rjlib

# copy input/output patches
mkdir -p $DESTDIR/pd
mkdir -p $CPDIR/pd
cp -v rjlib/pd/*.pd $DESTDIR/pd
cp -v rjlib/pd/*.pd $CPDIR/pd

# copy deprecated rj patches
mkdir -p $DESTDIR/rj_deprecated
cp -Rv rjlib/deprecated/* $DESTDIR/rj_deprecated

# copy rj external sources
mkdir -p ../libs/pd-externals/rj
cp -v rjlib/src/*.c ../libs/pd-externals/rj

# cleanup
rm -rf rjlib
