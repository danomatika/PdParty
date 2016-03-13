#! /bin/bash
#
# builds & uploads composer pack as a ZIP
#

ZIP=PdParty_composerpack

SSH_USER=danomatika
SSH_HOST=danomatika.com
SSH_DEST=/home/danomatika/danomatika.com/docs

CPDIR=../doc/composerpack

TEMP=$ZIP

WD=$(dirname $0)

###

cd $WD

mkdir -p $TEMP
cp -Rv $CPDIR/* $TEMP

# rj
git clone https://github.com/rjdj/rjlib.git
cp -Rv rjlib/rj $TEMP
rm -rf rjlib

# rc
git clone https://github.com/danomatika/rc-patches.git
cp -Rv rc-patches/rc $TEMP
rm -rf rc-patches

# zip
zip -r $ZIP $TEMP

# rsync zip
rsync -azv -e ssh $ZIP.zip $SSH_USER@$SSH_HOST:$SSH_DEST

# cleanup
rm -f $ZIP.zip
rm -rf $TEMP
