#! /bin/bash

WD=$(dirname $0)
destDir=../libs/pd

###

cd $WD

# get latest source
git clone git://github.com/libpd/libpd.git -b objc_midi

# remove uneeded makefiles
find libpd -name "GNUmakefile.am" -delete
find libpd -name "Makefile.am" -delete
find libpd -name "makefile" -delete
rm libpd/pure-data/extra/makefile.subdir

# we dont need the java or csharp wrappers
rm libpd/libpd_wrapper/z_csharp_helper.c
rm libpd/libpd_wrapper/z_csharp_helper.h

# remove expr~ since it's GPL, leave that up to devs
rm -rf libpd/pure-data/extra/expr~
rm libpd/pure-data/extra/expr-help.pd

# setup dest dir
mkdir -p $destDir

# copy license
cp -v libpd/LICENSE.txt $destDir

# copy sources
cp -Rv libpd/objc $destDir
cp -Rv libpd/pure-data $destDir
cp -Rv libpd/libpd_wrapper $destDir

# cleanup
rm -rf libpd

