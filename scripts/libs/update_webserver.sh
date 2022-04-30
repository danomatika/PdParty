#! /bin/sh
#
# this script automatically updates the sources for the GCDWebServer ios library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2017
#

# stop on error
set -e

SRC_DIR=GCDWebServer
DEST_DIR=../../libs/GCDWebServer

###

# move to this scripts dir
cd $(dirname $0)

# get latest source
git clone https://github.com/swisspol/GCDWebServer.git

# make folder
mkdir -p $DEST_DIR

# copy sources
cp -Rv $SRC_DIR/GCDWebServer $DEST_DIR/
cp -Rv $SRC_DIR/GCDWebDAVServer $DEST_DIR/
cp -Rv $SRC_DIR/LICENSE $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
