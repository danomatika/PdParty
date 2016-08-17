#! /bin/bash
#
# this script automatically downloads and the liblo OSC library for ios+simulator
#
# as long as the download link is formatted in the same way and folder
# structure are the same, this script should *just work*
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)
SRC_DIR=liblo
DEST_DIR=../../libs/liblo

###

# move to this scripts dir
cd $WD

# get latest source
git clone git://github.com/radarsat1/liblo.git

# create destination dirs
mkdir -pv $DEST_DIR/lo
mkdir -pv $DEST_DIR/src

cd $SRC_DIR

# generate configure
# adapted from https://gist.github.com/mikewoz/519121
./autogen.sh
MIN_IOS="6.0"
CF="-pipe -std=c99 -gdwarf-2 -mthumb -fembed-bitcode -Wno-trigraphs -fpascal-strings -O0 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden"
LF="-pipe -std=c99 -gdwarf-2 -mthumb"

# configure & build ios static lib
./configure \
	--host="arm-apple-darwin" \
	--enable-static --disable-shared --disable-dependency-tracking \
	--disable-tests --disable-network-tests --disable-tools --disable-examples \
	CC=`xcrun -f --sdk iphoneos clang` \
	AR=`xcrun -f --sdk iphoneos ar` \
	RANLIB=`xcrun -f --sdk iphoneos ranlib` \
	NM=`xcrun -f --sdk iphoneos nm` \
	CFLAGS="-arch armv7 -arch arm64 $CF -miphoneos-version-min=$MIN_IOS -I`xcrun --sdk iphoneos --show-sdk-path`/usr/include -isysroot `xcrun --sdk iphoneos --show-sdk-path`" \
	LDFLAGS="-arch armv7 -arch arm64 $LF -isysroot `xcrun --sdk iphoneos --show-sdk-path`"
make
cp src/.libs/liblo.a liblo-ios.a
make clean

# configure & build simulator static lib
./configure \
	--host="arm-apple-darwin" \
	--enable-static --disable-shared --disable-dependency-tracking \
	--disable-tests --disable-network-tests --disable-tools --disable-examples \
	CC=`xcrun -f --sdk iphonesimulator clang` \
	AR=`xcrun -f --sdk iphonesimulator ar` \
	RANLIB=`xcrun -f --sdk iphonesimulator ranlib` \
	NM=`xcrun -f --sdk iphonesimulator nm` \
	CFLAGS="-arch i386 -arch x86_64 $CF -miphoneos-version-min=$MIN_IOS -I`xcrun --sdk iphonesimulator --show-sdk-path`/usr/include -isysroot `xcrun --sdk iphonesimulator --show-sdk-path`" \
	LDFLAGS="-arch i386 -arch x86_64 $LD -isysroot `xcrun --sdk iphonesimulator --show-sdk-path`"
make
cp src/.libs/liblo.a liblo-sim.a
make clean

# link fat lib
lipo -create liblo-ios.a liblo-sim.a -output liblo.a

cd ../

# copy headers & lib
cp -v $SRC_DIR/lo/*.h $DEST_DIR/lo/
cp -v $SRC_DIR/liblo.a $DEST_DIR/

# cleanup
rm -rf $SRC_DIR
