#! /bin/sh
#
# generate various icon size sets using ImageMagick
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)
DEST=_generated

NAME=pdparty
ICON=$NAME-1024.png

# $1 - width
# $2 - height
# $3 - filename
function convert_icon() {
	convert $ICON -resize $1x$2 -density 72 $DEST/$3.png
}

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# iPhone Notification iOS 7-10
#              &
# iPad Notifications iOS 7-10
convert_icon 20 20 $NAME-20
convert_icon 40 40 $NAME-20@2x
convert_icon 60 60 $NAME-20@3x

# iPhone Settings iOS 5-10 & Spotlight iOS 5,6
# iPad Settings iOS 5-10
convert_icon 29 29 $NAME-29
convert_icon 58 58 $NAME-29@2x
convert_icon 87 87 $NAME-29@3x

# iPhone Spotlight iOS 7-10
# iPad Spotlight iOS 7-10
convert_icon 40 40 $NAME-40
convert_icon 80 80 $NAME-40@2x
convert_icon 120 120 $NAME-40@3x

# iPhone App iOS 5,6
convert_icon 57 57 $NAME-57
convert_icon 114 114 $NAME-57@2x

# iPhone App iOS 7-10
convert_icon 120 120 $NAME-60@2x
convert_icon 180 180 $NAME-60@3x

# iPad Spotlight iOS 5,6
convert_icon 50 50 $NAME-50
convert_icon 100 100 $NAME-50@2x

# iPad App iOS 5,6
convert_icon 72 72 $NAME-72
convert_icon 144 144 $NAME-72@2x

# iPad App iOS 7-10
convert_icon 76 76 $NAME-76
convert_icon 152 152 $NAME-76@2x

# iPad Pro App iOS 10
convert_icon 167 167 $NAME-83-5@2x

# App Store iOS
convert_icon 1024 1024 $NAME-1024

# browser scene icon with outline
ICON=$NAME-outline-1024.png
convert_icon 512 512 $NAME-512
