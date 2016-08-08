#! /bin/bash
#
# builds composer pack as a ZIP
#

TEMP=PdParty_composerpack

CP_DIR=../doc/composerpack
RES_DIR=../res/patches

ZIP=PdParty_composerpack

WD=$(dirname $0)

###

cd $WD

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
#git clone git://github.com/chr15m/PdDroidParty.git
git clone git://github.com/danomatika/PdDroidParty.git
mkdir -p $TEMP/lib/droidparty
cp -Rv PdDroidParty/droidparty-abstractions/* $TEMP/lib/droidparty
rm -rf PdDroidParty

# rj
#git clone git://github.com/rjdj/rjlib.git
git clone git://github.com/danomatika/rjlib.git
cp -Rv rjlib/rj $TEMP/lib
rm -rf rjlib

# rc
git clone https://github.com/danomatika/rc-patches.git
cp -Rv rc-patches/rc $TEMP/lib
rm -rf rc-patches

# templates
mkdir -p $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/soundinput.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/soundoutput.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/playback.pd $TEMP/templates/scenes/DroidTemplate/pd
cp -v $RES_DIR/lib/pd/recorder.pd $TEMP/templates/scenes/DroidTemplate/pd

# zip
zip -r $ZIP $TEMP

# cleanup
rm -rf $TEMP
