#! /bin/bash

WD=$(dirname $0)
destDir=../res/patches

###

cd $WD

# get latest source
git clone git://github.com/chr15m/PdDroidParty.git

# remove things we don't want to overwrite
rm -f PdDroidParty/bundled-abstractions/droidsystem.pd

# setup dest dir
mkdir -p $destDir
mkdir -p $destDir/lib/droidparty
mkdir -p $destDir/samples/droidparty

# copy patches
cp -Rv PdDroidParty/droidparty-tests/* $destDir/tests/droidparty
cp -Rv PdDroidParty/bundled-abstractions/* $destDir/lib/droidparty
cp -Rv PdDroidParty/droidparty-demos/* $destDir/samples/droidparty

# cleanup
rm -rf PdDroidParty

