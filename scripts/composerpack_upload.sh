#! /bin/sh
#
# uploads composer pack as a ZIP
#

# stop on error
set -e

ZIP=PdParty_composerpack

SSH_USER=danomatika
SSH_HOST=danomatika.com
SSH_DEST=/home/danomatika/danomatika.com/docs

###

# move to this scripts dir
cd $(dirname $0)

if [ -e "$ZIP" ] ; then
	echo "$ZIP.zip not found"
	exit 0
fi

# rsync zip
rsync -azv -e ssh $ZIP.zip $SSH_USER@$SSH_HOST:$SSH_DEST

# cleanup
rm -f $ZIP.zip
