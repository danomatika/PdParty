#! /bin/sh
#
# generate various icon size sets using ImageMagick
#
# Dan Wilcox <danomatika@gmail.com> 2016
#

WD=$(dirname $0)
DEST=_generated

# $1 filename & $2 suffix so: $1-$2.png
# ie. $1 "console" & $2 "1024" : console-1024.png
# $3 is size set to generate: 
#   browser: browser file types
#   nav: navigation buttons
#   slider: control view slider icon
#   control: control tab bar & menu buttons
function convert_icon() {
	local name=$(basename $1)
	if [ "$3" == "browser" ] ; then
		convert $1-$2.png -resize 24x24 $DEST/$name-24.png
		convert $1-$2.png -resize 48x48 $DEST/$name-48.png
		convert $1-$2.png -resize 72x72 $DEST/$name-72.png
	elif [ "$3" == "nav" ] ; then
		convert $1-$2.png -resize 24x24 $DEST/$name-24.png
		convert $1-$2.png -resize 48x48 $DEST/$name-48.png
		convert $1-$2.png -resize 72x72 $DEST/$name-72.png
	elif [ "$3" == "slider" ] ; then
		convert $1-$2.png -resize 36x36 $DEST/$name-36.png
		convert $1-$2.png -resize 72x72 $DEST/$name-72.png
		convert $1-$2.png -resize 108x108 $DEST/$name-108.png
	elif [ "$3" == "control" ] ; then
		convert $1-$2.png -resize 48x48 $DEST/$name-48.png
		convert $1-$2.png -resize 96x96 $DEST/$name-96.png
		convert $1-$2.png -resize 144x144 $DEST/$name-144.png
	else
		echo "unknown icon size set: \"$3\""
	fi
}

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# custom
convert_icon custom/controls 1024 nav
convert_icon custom/file 512 browser
convert_icon custom/patch 512 browser
convert_icon custom/pdparty 512 browser
convert_icon custom/record_filled 1024 control
convert_icon custom/record 1024 control

# icons8
convert_icon icons8/circuit 512 browser
convert_icon icons8/archive 512 browser
convert_icon icons8/console 512 control
convert_icon icons8/folder 512 browser
convert_icon icons8/high_volume 512 control
convert_icon icons8/info 512 nav
convert_icon icons8/info 512 control
#convert_icon icons8/menu 512 nav
convert_icon icons8/micro2 512 slider
convert_icon icons8/pause 512 control
convert_icon icons8/play 512 control
convert_icon icons8/reload 512 control
convert_icon icons8/repeat 512 control
convert_icon icons8/tape_drive 512 browser
