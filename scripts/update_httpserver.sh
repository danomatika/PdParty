#! /bin/bash

WD=$(dirname $0)
DEST=../libs/CocoaHTTPServer

###

cd $WD

# get latest source
git clone git://github.com/robbiehanson/CocoaHTTPServer.git

# make folder
mkdir -p $DEST

# copy rj sources
cp -Rv CocoaHTTPServer/Core $DEST
cp -Rv CocoaHTTPServer/Extensions $DEST
cp -Rv CocoaHTTPServer/Vendor $DEST
cp -Rv CocoaHTTPServer/LICENSE.txt $DEST

# cleanup
rm -rfv CocoaHTTPServer

