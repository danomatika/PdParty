#! /bin/bash

WD=$(dirname $0)
srcDir=libpd
destDir=../libs/pd

###

cd $WD

# get latest source
git clone git://github.com/libpd/libpd.git -b pd_045-4

# remove uneeded makefiles
find $srcDir -name "GNUmakefile.am" -delete
find $srcDir -name "Makefile.am" -delete
find $srcDir -name "makefile" -delete
rm $srcDir/pure-data/extra/makefile.subdir

# we dont need the csharp wrapper
rm $srcDir/libpd_wrapper/util/z_hook_util.c
rm $srcDir/libpd_wrapper/util/z_hook_util.h

# leave pd~ out for now
rm -rf $srcDir/pure-data/extra/pd~

# setup dest dir
mkdir -p $destDir

# copy license
cp -v $srcDir/LICENSE.txt $destDir

# copy extras patches to patches lib folder
mkdir -p ../res/patches/lib/pd
find $srcDir/pure-data/extra -name "*-help.pd" -delete # don't need help files
mv -v $srcDir/pure-data/extra/*.pd ../res/patches/lib/pd

# copy sources
cp -Rv $srcDir/objc $destDir
cp -Rv $srcDir/pure-data $destDir
cp -Rv $srcDir/libpd_wrapper $destDir

# cleanup
rm -rf $srcDir

