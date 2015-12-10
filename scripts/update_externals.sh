#! /bin/bash
#
# clones and copies externals sources/patches from git.puredata.info
#
# browse: http://git.puredata.info/cgit
#

WD=$(dirname $0)

SRC_DIR=../libs/pd-externals
PATCH_DIR=../bin/data/pd-externals

###

cd $WD

# ggee
git clone https://git.puredata.info/cgit/svn2git/libraries/ggee.git
mkdir -p $SRC_DIR/ggee
cp -v ggee/control/getdir.c $SRC_DIR/ggee
cp -v ggee/control/stripdir.c $SRC_DIR/ggee
cp -v ggee/filters/moog~.c $SRC_DIR/ggee
rm -rf ggee

# mrpeach
git clone https://git.puredata.info/cgit/svn2git/libraries/mrpeach.git
#mkdir -p $SRC_DIR/mrpeach/osc
#cp -Rv mrpeach/osc/LICENSE.txt $SRC_DIR/mrpeach/osc
#cp -Rv mrpeach/osc/*.h $SRC_DIR/mrpeach/osc
#cp -Rv mrpeach/osc/*.c $SRC_DIR/mrpeach/osc
#mkdir -p $SRC_DIR/mrpeach/net
#cp -Rv mrpeach/net/LICENSE.txt $SRC_DIR/mrpeach/net
#cp -Rv mrpeach/net/*.h $SRC_DIR/mrpeach/net
#cp -Rv mrpeach/net/*.c $SRC_DIR/mrpeach/net
mkdir -p $SRC_DIR/mrpeach/midifile
cp -Rv mrpeach/midifile/*.c $SRC_DIR/mrpeach/midifile
#cp -Rv mrpeach/sqosc~/*.c $SRC_DIR/mrpeach # doesn't build on ios
rm -rf mrpeach

