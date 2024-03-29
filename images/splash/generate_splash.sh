#! /bin/sh
#
# note: As of PdParty 1.3.0, this is no longer used in favor of splash.pdf on
#       a the Launch Screen.storyboard.
#
# generate various LaunchImage size sets using ImageMagick
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)
DEST=_generated

NAME=splash
SPLASH=$NAME.png

# $1 - width
# $2 - height
# $3 - filename
function convert_splash() {
	local width=$(echo "$1 * 0.3" | bc)
	local height=$(echo "$2 * 0.3" | bc)
	convert $SPLASH -background white -alpha remove -gravity center \
	                -scale $widthx$height $4 $5 -extent $1x$2 -density 72 \
	                $DEST/$3.png
}

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# iPad Portrait iOS 5,6 & iOS 7-9
convert_splash 768 1024  $NAME-ipad5-9
convert_splash 1536 2048 $NAME-ipad5-9@2x

# iPhone Portrait iOS 5,6 & iOS 7-9
convert_splash 320 480  $NAME-iphone5-9
convert_splash 640 960  $NAME-iphone5-9@2x
convert_splash 640 1136 $NAME-iphone5-9@retina4

# iPhone Portrait iOS 7-9
convert_splash 640 960  $NAME-iphone7-9@2x
convert_splash 640 1136 $NAME-iphone7-9@retina4

# iPhone Portrait iOS 8,9
convert_splash 1242 2208 $NAME-iphone8-9@retina-hd5-5
convert_splash 750 1334  $NAME-iphone8-9@retina-hd4-7

# iPhone X Portrait iOS 11+
convert_splash 1125 2436 $NAME-phone11@iphone-x
