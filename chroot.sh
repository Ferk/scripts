#!/bin/sh
#
# chroot script
#

if [ $(id -u) != 0 ]
then
    echo "You need to be root to run chroot"
    exit 1
fi

rootd=$PWD
echo "New root: $rootd"

if ! [ -x "$rootd/bin/bash" ]
then
    echo "No $rootd/bin/bash file found. Won't set this directory as root."
    exit 2
fi


mount -t proc proc "$rootd/proc/"
mount -t sysfs sys "$rootd/sys/"
mount -o bind /dev "$rootd/dev/"
mount -t devpts pts "$rootd/dev/pts/"

chroot "$rootd" "$@"


