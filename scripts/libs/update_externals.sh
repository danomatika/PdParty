#! /bin/sh
#
# clones and copies externals sources/patches from git.puredata.info
#
# browse: http://git.puredata.info/cgit
#
# Dan Wilcox <danomatika@gmail.com> 2012
#

# stop on error
set -e

DEST_DIR=../../libs/pd-externals

###

# move to this scripts dir
cd $(dirname $0)

# ggee
git clone https://github.com/pd-externals/ggee
mkdir -p $DEST_DIR/ggee
cp -v ggee/control/getdir.c $DEST_DIR/ggee
cp -v ggee/control/stripdir.c $DEST_DIR/ggee
cp -v ggee/filters/moog~.c $DEST_DIR/ggee
rm -rf ggee

# mrpeach
git clone https://github.com/pd-externals/midifile.git --depth 1
mkdir -p $DEST_DIR/mrpeach/midifile
cp -Rv midifile/*.c $DEST_DIR/mrpeach/midifile/
rm -rf midifile
