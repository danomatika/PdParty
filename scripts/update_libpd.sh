#! /bin/bash

WD=$(dirname $0)
destDir=../libs/pd

###

cd $WD

# get latest source
git clone git://github.com/libpd/libpd.git -b pd_045-4

# remove uneeded makefiles
find libpd -name "GNUmakefile.am" -delete
find libpd -name "Makefile.am" -delete
find libpd -name "makefile" -delete
rm libpd/pure-data/extra/makefile.subdir

# we dont need the csharp wrapper
rm libpd/libpd_wrapper/util/z_hook_util.c
rm libpd/libpd_wrapper/util/z_hook_util.h

# leave pd~ out for now
rm -rf libpd/pure-data/extra/pd~

# setup dest dir
mkdir -p $destDir

# copy license
cp -v libpd/LICENSE.txt $destDir

# copy extras patches to patches lib folder
mkdir -p ../res/patches/lib/pd
find libpd/pure-data/extra -name "*-help.pd" -delete # don't need help files
mv -v libpd/pure-data/extra/*.pd ../res/patches/lib/pd

# copy sources
cp -Rv libpd/objc $destDir
cp -Rv libpd/pure-data $destDir
cp -Rv libpd/libpd_wrapper $destDir

# cleanup
rm -rf libpd

