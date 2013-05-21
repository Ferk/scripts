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

for cmd in "$rootd/bin/bash" "$rootd/bin/sh"
do
    if [ -x "$cmd" ]
    then
	CMD=${cmd#$rootd}
	break
    fi
done


if [ -z "$CMD" ]
then
    echo "No shell found in the directory tree. Won't set it as root."
    exit 2
fi


mount -t proc proc "$rootd/proc/"
mount -t sysfs sys "$rootd/sys/"
mount -o bind /dev "$rootd/dev/"
mount -t devpts pts "$rootd/dev/pts/"

chroot "$rootd" "$CMD"


