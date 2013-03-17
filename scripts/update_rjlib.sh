#! /bin/bash

WD=$(dirname $0)

###

cd $WD

# get latest source
git clone git://github.com/rjdj/rjlib.git rjlib

# copy input/output patches
cp -v rjlib/pd/*.pd ../res/patches/pd

# copy rj sources
#cp -Rv rjlib/rj ../bin/data/externals

# cleanup
rm -rf rjlib

