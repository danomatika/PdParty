#! /bin/bash
#
# this script automatically updates the sources for the CocoaHTTPServer ios library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2013
#

WD=$(dirname $0)
SRC_DIR=CocoaHTTPServer
DEST_DIR=../libs/CocoaHTTPServer

###

cd $WD

# get latest source
git clone git://github.com/robbiehanson/CocoaHTTPServer.git

# make folder
mkdir -p $DEST_DIR

# copy sources
cp -Rv $SRC_DIR/Core $DEST_DIR/
cp -Rv $SRC_DIR/Extensions $DEST_DIR/
cp -Rv $SRC_DIR/Vendor $DEST_DIR/
cp -Rv $SRC_DIR/LICENSE.txt $DEST_DIR/

# cleanup
rm -rfv $SRC_DIR
