#! /bin/bash
#
# clones and copies externals sources/patches from git.puredata.info
#
# browse: http://git.puredata.info/cgit
#
# Dan Wilcox <danomatika@gmail.com> 2012
#

WD=$(dirname $0)

DEST_DIR=../../libs/pd-externals

###

cd $WD

# ggee
git clone https://git.puredata.info/cgit/svn2git/libraries/ggee.git
mkdir -p $DEST_DIR/ggee
cp -v ggee/control/getdir.c $DEST_DIR/ggee
cp -v ggee/control/stripdir.c $DEST_DIR/ggee
cp -v ggee/filters/moog~.c $DEST_DIR/ggee
rm -rf ggee

# mrpeach
git clone https://git.puredata.info/cgit/svn2git/libraries/mrpeach.git
mkdir -p $DEST_DIR/mrpeach/midifile
cp -Rv mrpeach/midifile/*.c $DEST_DIR/mrpeach/midifile/
rm -rf mrpeach
