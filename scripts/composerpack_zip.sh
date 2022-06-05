#! /bin/sh
#
# builds composer pack as a ZIP
#

# stop on error
set -e

TEMP=PdParty_composerpack

CP_DIR=../doc/composerpack
RES_DIR=../res/patches

ZIP=PdParty_composerpack

###

# move to this scripts dir
cd $(dirname $0)

mkdir -p $TEMP
cp -Rv $CP_DIR/* $TEMP

# samples & tests
cp -Rv $RES_DIR/samples $TEMP
cp -Rv $RES_DIR/tests $TEMP

# input & output abstractions
mkdir -p $TEMP/lib/pd
cp -Rv $RES_DIR/lib/pd/soundinput.pd $TEMP/lib/pd
cp -Rv $RES_DIR/lib/pd/soundoutput.pd $TEMP/lib/pd
cp -Rv $RES_DIR/lib/pd/playback.pd $TEMP/lib/pd
cp -Rv $RES_DIR/lib/pd/recorder.pd $TEMP/lib/pd

# dummy abstractions
mkdir -p $TEMP/lib/pdparty
mkdir -p $TEMP/lib/droidparty
cp -Rv $RES_DIR/lib/pdparty/*.pd $TEMP/lib/pdparty
cp -Rv $RES_DIR/lib/droidparty/droidsystem.pd $TEMP/lib/droidparty
cp -Rv $RES_DIR/lib/droidparty/mknob.pd $TEMP/lib/droidparty

# droidparty
git clone https://github.com/chr15m/PdDroidParty.git --depth 1
mkdir -p $TEMP/lib/droidparty
cp -Rv PdDroidParty/droidparty-abstractions/* $TEMP/lib/droidparty
rm -rf PdDroidParty

# rj
git clone https://github.com/rjdj/rjlib.git --depth 1
#git clone git://github.com/danomatika/rjlib.git --depth 1
cp -Rv rjlib/rj $TEMP/lib
rm -rf rjlib

# rc
git clone https://github.com/danomatika/rc-patches.git --depth 1
cp -Rv rc-patches/rc $TEMP/lib
rm -rf rc-patches

# templates
mkdir -p $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/soundinput.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/soundoutput.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/playback.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/recorder.pd $TEMP/templates/scenes/DroidTemplate/pd

# rename .md to .txt as most OS have no default way to open them
mv -v $TEMP/README.md $TEMP/README.txt
mv -v $TEMP/templates/devices/README.md $TEMP/templates/devices/README.txt

# zip
zip -r $ZIP $TEMP

# cleanup
rm -rf $TEMP
