#! /bin/bash

WD=$(dirname $0)
destDir=../libs/pd

###

cd $WD

# get latest source
git clone git://github.com/libpd/libpd.git

# remove uneeded makefiles
find libpd -name "GNUmakefile.am" -delete
find libpd -name "Makefile.am" -delete
find libpd -name "makefile" -delete
rm libpd/pure-data/extra/makefile.subdir

# we dont need the csharp wrapper
rm libpd/libpd_wrapper/util/z_hook_util.c
rm libpd/libpd_wrapper/util/z_hook_util.h

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

# copy extra patches to patches dir
mkdir -p ../res/patches/lib/pd
rm libpd/pure-data/extra/*-help.pd # don't need help files
cp -v libpd/pure-data/extra/*.pd ../res/patches/lib/pd

# cleanup
rm -rf libpd

