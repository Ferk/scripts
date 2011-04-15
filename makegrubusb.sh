#!/bin/bash

############################### PROGRAM DETAILS ################################
##                                                                            ##
##          FILE:  MultiBootUSB.sh                                            ##
##                                                                            ##
##         USAGE:  ./MultiBootUSB.sh                                          ##
##                                                                            ##
##       OPTIONS:  ---                                                        ##
##                                                                            ##
##   DESCRIPTION:  Shell script to Install multiple linux live distributions  ##
##                 into USB disk/Flash drive/Pen drive and make it bootable.  ##
##                                                                            ##
##  REQUIREMENTS:  Linux, Grub-2                                              ##
##                                                                            ##
##          BUGS:  ---                                                        ##
##                                                                            ##
##         NOTES:  Run this script with root privilege.                       ##
##                 Refer doc folder for tutorial with screenshots.            ##
##                                                                            ##
##       AUTHORS:  Ramesh & Sundar                                            ##
##                                                                            ##
##       VERSION:  Beta 3.0                                                   ##
##                                                                            ##
##      REVISION:  001                                                        ##
##                                                                            ##
##       UPDATED:  11-July-2010 09:00:00 IST                                  ##
##                                                                            ##
##       LICENSE:  GNU General Public License                                 ##
##                                                                            ##
################################################################################


################################ LICENSE TERMS #################################
##  This program is free software: you can redistribute it and/or modify      ##
##  it under the terms of the GNU General Public License as published by      ##
##  the Free Software Foundation, either version 3 of the License, or         ##
##  (at your option) any later version.                                       ##
##                                                                            ##
##                                                                            ##
##  This program is distributed in the hope that it will be useful,           ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of            ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             ##
##  GNU General Public License for more details.                              ##
##                                                                            ##
##  You should have received a copy of the GNU General Public License         ##
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.     ##
################################################################################



function error() {
	echo "Error: $1"
	exit 1
}


################################################################################
##                                                                            ##
##                      Actual Script starts from here                        ##
##                                                                            ##
################################################################################



################################################################################

############################## SET FOLDER DETAILS ##############################

SCRIPT_ROOT=$( cd -P -- "$(dirname -- "$0")" && pwd -P )


TEMPROOT=`TEMPROOT 2>/dev/null` || TEMPROOT=/tmp/temp_liveusb_root$$
trap "rm -rf $TEMPROOT" 0 1 2 5 15

if [ -d ${TEMPROOT} -a ${TEMPROOT} != "/" ] ; then
	rm -rf ${TEMPROOT}
fi

mkdir -p ${TEMPROOT}/usb
mkdir -p ${TEMPROOT}/live

USB_MOUNT=${TEMPROOT}/usb
LIVE_MOUNT=${TEMPROOT}/live

TEMPFILE=`TEMPFILE 2>/dev/null` || TEMPFILE=${TEMPROOT}/tempfile

WHIPTAIL=whiptail


################################################################################


########################## SELECT USB DRIVE TO USE #############################

for LIST in `find /dev/disk/by-path/ -type l -iname \*usb\*scsi\* -print0 | xargs -0 -iD readlink -f D | grep -v [0-9] | sort `
do
	SIZE=`fdisk -l $LIST | grep Disk | grep bytes | cut -d ":" -f 2 | cut -d " " -f 2-3 | tr -d "," | tr " " "-"`
	DRIVES="$DRIVES$LIST [$SIZE] off "
done


if [ -z "$DRIVES" ] ; then
	echo "No USB Drive is available"
	exit 1
fi

${WHIPTAIL} \
        --radiolist \
        "Select USB Drive. Use UP or DOWN arrow key to move. Press SPACE BAR to select." \
        40 50 30 \
        $DRIVES \
        2> $TEMPFILE

USB_DISK=`cat $TEMPFILE`

if [ -z "${USB_DISK}" ] ; then
	echo "No USB Drive is selected"
	exit 1
fi


SIZE=`fdisk -l $USB_DISK | grep Disk | grep bytes | cut -d ":" -f 2 | cut -d " " -f 2-3 | tr -d "," `

${WHIPTAIL} \
        --inputbox \
        "Confirm USB Drive [${SIZE}] to use. All Data will be *deleted*" \
        10 40 \
        "$USB_DISK " \
        2> $TEMPFILE

USB_DISK=`cat $TEMPFILE | cut -d " " -f 1`

find /dev/disk/by-path/ -type l -iname \*usb\*scsi\* -print0 | xargs -0 -iD readlink -f D | grep ${USB_DISK} 1>/dev/null

if [ $? -ne 0 ] ; then
        echo "USB Disk [${USB_DISK}] is not available"
        exit 1
fi

for UDI in $(/usr/bin/hal-find-by-capability --capability storage)
	do
		if [[ $(hal-get-property --udi $UDI --key block.device) = "${USB_DISK}" ]] ; then
			VENDOR=$(hal-get-property --udi $UDI --key storage.vendor)
			PARENT_UDI=$(hal-find-by-property --key block.storage_device --string $UDI)
			MODEL=$(hal-get-property --udi $UDI --key storage.model)
			LABEL=$(hal-get-property --udi $PARENT_UDI --key volume.label)
			MEDIA_SIZE=$(hal-get-property --udi $UDI --key storage.removable.media_size)
			USB_SIZE=`expr $MEDIA_SIZE / 1000000000`
			USB_DETAILS=`echo "$VENDOR $MODEL $USB_DISK $LABEL ${USB_SIZE} GB"`
		fi
	done



################################################################################

############################ FINAL CONFIRMATION ################################

${WHIPTAIL} --yesno --defaultno --title "Final Confirmation" \
"Review below details and select <Yes> to proceed or <No> to abort. \n\n\n\
=============================================================== \n\
Following Drive will be used for Live USB. \n\
All files in the Drive will be *** DELETED *** \n\n\
	[ ${USB_DETAILS} ] \n\n\
===============================================================" \
		40 75

if [ $? -eq 1  ] ; then
	exit 1
fi

################################################################################

################################################################################

START=`date +%H:%M:%S`
echo $START

################################### FORMAT #####################################
echo "Formatting USB disk $(USB_DISK)..."

sudo umount ${USB_DISK}* 2>/dev/null

if (grep ${USB_DISK} /proc/mounts) ; then
	error "Unmount all partitions of ${USB_DISK} and run the script again"
fi

sudo fdisk ${USB_DISK} << END
p
d
p
n
p
1


a
1
t
b
w
q
END

sudo mkfs.vfat -F 32 -n "USB_Pen" ${USB_DISK}1

################################################################################

#################################### GRUB ######################################
echo "Installing GRUB..."


sudo mount -t vfat ${USB_DISK}1 ${USB_MOUNT}

sudo grub-install --no-floppy --recheck --root-directory=${USB_MOUNT} ${USB_DISK}

sudo cat <<EOF>> ${USB_MOUNT}/boot/grub/grub.cfg

set default="1"
set timeout=30
set color_normal=white/black
set color_highlight=white/light-gray

menuentry "First Partition of First HDD" {
set root=(hd0,1)
chainloader +1
}

GRUB_GFXMODE=800x600x16
insmod vbe

EOF

sudo mkdir -p ${USB_MOUNT}/boot/iso

################################################################################

#################################### FINAL #####################################


echo "Disk Synchronization in Progress ...."
sudo sync
sudo umount ${USB_MOUNT}

END=`date +%H:%M:%S`

df -h

echo "Start Time: $START"
echo "End Time  : $END"

echo "Installation completed, remove USB disk"

exit 0

##################################### END ######################################



