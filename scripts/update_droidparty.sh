#! /bin/bash
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)

DESTDIR=../res/patches
CPDIR=../pdparty-composer-pack

###

cd $WD

# get latest source
#git clone git://github.com/chr15m/PdDroidParty.git
git clone git://github.com/danomatika/PdDroidParty.git

# remove things we don't want to overwrite
rm -f PdDroidParty/bundled-abstractions/droidsystem.pd

# setup dest dir
mkdir -p $DESTDIR
mkdir -p $DESTDIR/lib/droidparty
mkdir -p $DESTDIR/samples/droidparty
mkdir -p $CPDIR/droidparty

# copy patches
cp -Rv PdDroidParty/droidparty-tests/* $DESTDIR/tests/droidparty
cp -Rv PdDroidParty/bundled-abstractions/* $DESTDIR/lib/droidparty
cp -Rv PdDroidParty/droidparty-demos/* $DESTDIR/samples/droidparty
cp -Rv PdDroidParty/droidparty-abstractions/* $CPDIR/droidparty

# cleanup
rm -rf PdDroidParty
