#! /bin/bash
#
# this script automatically updates the sources for the PGMidi ios library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2013
#

WD=$(dirname $0)
SRC_DIR=PGMidi
DEST_DIR=../../libs/pgmidi

###

# move to this scripts dir
cd $WD

# get latest source
git clone git://github.com/petegoodliffe/PGMidi.git

# create destination dir
mkdir -pv $DEST_DIR

# copy readme/license
cp -v $SRC_DIR/README.md $DEST_DIR/

# copy sources
cp -v $SRC_DIR/Sources/PGMidi/* $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
