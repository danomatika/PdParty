#! /bin/sh
#
# Dan Wilcox <danomatika@gmail.com> 2014
#

# stop on error
set -e

SRC_DIR=PdDroidParty
DEST_DIR=../../res/patches

###

# move to this scripts dir
cd $(dirname $0)

# get latest source
git clone https://github.com/chr15m/PdDroidParty.git

# remove things we don't need
rm -rf $SRC_DIR/droidparty-demos/vocoder-rjdj

# remove things we don't want to overwrite
rm -f $SRC_DIR/bundled-abstractions/droidsystem.pd

# setup dest dir
mkdir -p $DEST_DIR
mkdir -p $DEST_DIR/lib/droidparty
mkdir -p $DEST_DIR/samples/droidparty

# copy patches
cp -Rv $SRC_DIR/droidparty-tests/* $DEST_DIR/tests/droidparty/
cp -Rv $SRC_DIR/bundled-abstractions/* $DEST_DIR/lib/droidparty/
cp -Rv $SRC_DIR/droidparty-demos/* $DEST_DIR/samples/droidparty/

# cleanup
rm -rf $SRC_DIR
