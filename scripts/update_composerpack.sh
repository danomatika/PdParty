#! /bin/bash
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)

CPDIR=../doc/composerpack

###

cd $WD

mkdir -p $CPDIR/pdparty
mkdir -p $CPDIR/droidparty

cp -Rv ../res/patches/lib/rj/*.pd $CPDIR/pdparty
cp -Rv ../res/patches/lib/pdparty/*.pd $CPDIR/pdparty
cp -Rv ../res/patches/lib/droidparty/droidsystem.pd $CPDIR/droidparty
cp -Rv ../res/patches/lib/droidparty/mknob.pd $CPDIR/droidparty
