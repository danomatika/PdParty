#! /bin/sh
#
# this script automatically updates the sources for the MBProgressHUD ios library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2012
#

# stop on error
set -e

SRC_DIR=MBProgressHUD
DEST_DIR=../../libs/MBProgressHUD

###

# move to this scripts dir
cd $(dirname $0)

# get latest source
git clone https://github.com/jdg/MBProgressHUD.git

# create destination dir
mkdir -pv $DEST_DIR

# copy readme/license
cp -v $SRC_DIR/README.mdown $DEST_DIR/
cp -v $SRC_DIR/LICENSE $DEST_DIR/

# copy sources
cp -v $SRC_DIR/MBProgressHUD.h $DEST_DIR/
cp -v $SRC_DIR/MBProgressHUD.m $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
