#! /bin/bash
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
function convert-icon() {
	convert $ICON -resize $1x$2 -density 72 $DEST/$3.png
}

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# iPhone Notification iOS 7-10
#              &
# iPad Notifications iOS 7-10
convert-icon 20 20 $NAME-20
convert-icon 40 40 $NAME-20@2x
convert-icon 60 60 $NAME-20@3x

# iPhone Settings iOS 5-10 & Spotlight iOS 5,6
# iPad Settings iOS 5-10
convert-icon 29 29 $NAME-29
convert-icon 58 58 $NAME-29@2x
convert-icon 87 87 $NAME-29@3x

# iPhone Spotlight iOS 7-10
# iPad Spotlight iOS 7-10
convert-icon 40 40 $NAME-40
convert-icon 80 80 $NAME-40@2x
convert-icon 120 120 $NAME-40@3x

# iPhone App iOS 5,6
convert-icon 57 57 $NAME-57
convert-icon 114 114 $NAME-57@2x

# iPhone App iOS 7-10
convert-icon 120 120 $NAME-60@2x
convert-icon 180 180 $NAME-60@3x

# iPad Spotlight iOS 5,6
convert-icon 50 50 $NAME-50
convert-icon 100 100 $NAME-50@2x

# iPad App iOS 5,6
convert-icon 72 72 $NAME-72
convert-icon 144 144 $NAME-72@2x

# iPad App iOS 7-10
convert-icon 76 76 $NAME-76
convert-icon 152 152 $NAME-76@2x

# iPad Pro App iOS 10
convert-icon 167 167 $NAME-83-5@2x

# App Store iOS
convert-icon 1024 1024 $NAME-1024
