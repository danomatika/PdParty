#! /bin/bash

WD=$(dirname $0)

###

# move to this scripts dir
cd $WD

# get latest source
git clone git://github.com/robbiehanson/CocoaLumberjack.git

# create dir
mkdir -p ../src/Lumberjack

# copy
cp -v CocoaLumberjack/Lumberjack/* ../src/Lumberjack

# cleanup
rm -rf CocoaLumberjack

