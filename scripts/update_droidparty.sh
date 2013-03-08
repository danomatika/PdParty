#! /bin/bash

WD=$(dirname $0)
destDir=../res/patches

###

cd $WD

# get latest source
git clone git://github.com/chr15m/PdDroidParty.git

# setup dest dir
mkdir -p $destDir

# copy patches
cp -Rv PdDroidParty/droidparty-tests $destDir/tests
#cp -Rv PdDroidParty/droidparty-demos $destDir

# cleanup
rm -rf PdDroidParty

