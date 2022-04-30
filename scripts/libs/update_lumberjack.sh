#! /bin/sh
#
# this script automatically updates the sources for the CocoaLumberjack library
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2017
#

# stop on error
set -e

VER=3.7.4

SRC_DIR=CocoaLumberjack
DEST_DIR=../../libs/CocoaLumberjack

###

# move to this scripts dir
cd $(dirname $0)

# get latest source
git clone https://github.com/CocoaLumberjack/CocoaLumberjack.git --branch $VER --depth 1

# make folder
mkdir -p $DEST_DIR

# remove stuff we don't need
rm -r $SRC_DIR/Sources/CocoaLumberjack/CLI
#rm -r $SRC_DIR/Sources/CocoaLumberjack/Extensions
#rm -r $SRC_DIR/Sources/CocoaLumberjack/include/CocoaLumberjack
rm -r $SRC_DIR/Sources/CocoaLumberjack/Supporting\ Files/CocoaLumberjack-Info.plist
rm -r $SRC_DIR/Sources/CocoaLumberjack/DDAbstractDatabaseLogger.m

# copy sources
#cp -Rv $SRC_DIR/Sources/CocoaLumberjack/Extensions $DEST_DIR/
cp -Rv $SRC_DIR/Sources/CocoaLumberjack/include/CocoaLumberjack/*.h $DEST_DIR/
cp -Rv $SRC_DIR/Sources/CocoaLumberjack/Supporting\ Files/*.h $DEST_DIR/
cp -Rv $SRC_DIR/Sources/CocoaLumberjack/*.h $DEST_DIR/
cp -Rv $SRC_DIR/Sources/CocoaLumberjack/*.m $DEST_DIR/
cp -Rv $SRC_DIR/LICENSE $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
