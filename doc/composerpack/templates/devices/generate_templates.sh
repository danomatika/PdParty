#! /bin/sh
#
# generate various device template patch sizes
# logical resolutions from https://iosref.com/res
#
# Dan Wilcox <danomatika@gmail.com> 2022
#

##### variables

TB_H_IPHONE=44
TB_H_IPAD=64

##### functions

# create empty patch file
# $1 filepath
# $2 width
# $3 height
# $4 toolbar height
function create_patch() {
	local h=$(expr $3 - $4)
	echo "#N canvas 200 200 $2 $h 10;" > "$1"
	echo "$2 $h -> $1"
}

# create template iphone set: -landscape.pd & -portrait.pd
# $1 base filepath without .pd extension
# $2 portrait width
# $3 portrait height
function iphone_template() {
	create_patch "iphone/${1}-landscape.pd" $2 $3 $TB_H_IPHONE
	create_patch "iphone/${1}-portrait.pd"  $3 $2 $TB_H_IPHONE
}

# create template ipad set: -landscape.pd & -portrait.pd
# $1 base filepath without .pd extension
# $2 portrait width
# $3 portrait height
function ipad_template() {
	# half-size template patches, otherwise they are too big
	local w=$(expr $2 / 2)
	local h=$(expr $3 / 2)
	create_patch "ipad/${1}-landscape.pd" $w $h $TB_H_IPAD
	create_patch "ipad/${1}-portrait.pd"  $h $w $TB_H_IPAD
}

##### main

cd $(dirname $0)

# iphone
iphone_template iphone-13-pro-max 428 926
iphone_template iphone-13-pro     390 844
iphone_template iphone-13-mini    375 812
iphone_template iphone-11-pro-max 414 896
iphone_template iphone-11-pro     375 812
iphone_template iphone-11         414 896
iphone_template iphone-8-plus     414 736
iphone_template iphone-se3        375 667
iphone_template iphone-se1        320 568

# ipad
ipad_template ipad-pro5          1024 1366
ipad_template ipad-pro3           834 1194
ipad_template ipad-air5           820 1180
ipad_template ipad-9              810 1080
ipad_template ipad-mini6          744 1133
ipad_template ipad-air3           834 1112
ipad_template ipad-6              768 1024
ipad_template ipad-mini5          768 1024
