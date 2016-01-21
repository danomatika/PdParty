#! /bin/bash
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)

CPDIR=../doc/composerpack

###

cd $WD

mkdir -p $CPDIR/rj
mkdir -p $CPDIR/droidparty

cp -Rv ../res/patches/lib/rj/*.pd $CPDIR/rj
cp -Rv ../res/patches/lib/droidparty/droidsystem.pd $CPDIR/droidparty
cp -Rv ../res/patches/lib/droidparty/mknob.pd $CPDIR/droidparty