#! /bin/bash
#
# checks out and copies externals sources/patches from pd svn
#
# browse: https://pure-data.svn.sourceforge.net/svnroot/pure-data/tags/pd-extended/0.42.5/externals/
#

WD=$(dirname $0)

VER=0.42.5

SRC_DIR=../libs/pd/externals/
PATCH_DIR=../bin/data/pd-externals

###

cd $WD

## get latest source
#svn export https://pure-data.svn.sourceforge.net/svnroot/pure-data/tags/pd-extended/$VER/externals/ externals
#svn export https://pure-data.svn.sourceforge.net/svnroot/pure-data/branches/pd-extended/0.43/externals/ externals
svn export https://pure-data.svn.sourceforge.net/svnroot/pure-data/trunk/externals/ externals

## copy external abs and source

# ggee
mkdir -p $SRC_DIR/ggee
cp -v externals/ggee/control/getdir.c $SRC_DIR/ggee
cp -v externals/ggee/control/stripdir.c $SRC_DIR/ggee
cp -v externals/ggee/filters/moog~.c $SRC_DIR/ggee

# mrpeach
#mkdir -p $SRC_DIR/mrpeach/osc
#cp -Rv externals/mrpeach/osc/LICENSE.txt $SRC_DIR/mrpeach/osc
#cp -Rv externals/mrpeach/osc/*.h $SRC_DIR/mrpeach/osc
#cp -Rv externals/mrpeach/osc/*.c $SRC_DIR/mrpeach/osc
#mkdir -p $SRC_DIR/mrpeach/net
#cp -Rv externals/mrpeach/net/LICENSE.txt $SRC_DIR/mrpeach/net
#cp -Rv externals/mrpeach/net/*.h $SRC_DIR/mrpeach/net
#cp -Rv externals/mrpeach/net/*.c $SRC_DIR/mrpeach/net
mkdir -p $SRC_DIR/mrpeach/midifile
cp -Rv externals/mrpeach/midifile/*.c $SRC_DIR/mrpeach/midifile
#cp -Rv externals/mrpeach/sqosc~/*.c $SRC_DIR/mrpeach # doesn't build on ios

## cleanup
rm -rf externals
