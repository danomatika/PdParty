#! /bin/bash

WD=$(dirname $0)
DEST=_generated

NAME=pdparty
ICON=$NAME-1024.png

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# iOS 6 iPhone
convert $ICON -resize 57x57 -density 72 $DEST/$NAME-57.png
convert $ICON -resize 114x114 -density 72 $DEST/$NAME-57@2x.png

# iOS 6 iPad
convert $ICON -resize 72x72 -density 72 $DEST/$NAME-72.png
convert $ICON -resize 144x144 -density 72 $DEST/$NAME-144.png
