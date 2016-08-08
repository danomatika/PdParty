#! /bin/bash
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

WD=$(dirname $0)

DEST_DIR=../res/patches

###

cd $WD

# get latest source
#git clone git://github.com/chr15m/PdDroidParty.git
git clone git://github.com/danomatika/PdDroidParty.git

# remove things we don't want to overwrite
rm -f PdDroidParty/bundled-abstractions/droidsystem.pd

# setup dest dir
mkdir -p $DEST_DIR
mkdir -p $DEST_DIR/lib/droidparty
mkdir -p $DEST_DIR/samples/droidparty

# copy patches
cp -Rv PdDroidParty/droidparty-tests/* $DEST_DIR/tests/droidparty
cp -Rv PdDroidParty/bundled-abstractions/* $DEST_DIR/lib/droidparty
cp -Rv PdDroidParty/droidparty-demos/* $DEST_DIR/samples/droidparty

# cleanup
rm -rf PdDroidParty
