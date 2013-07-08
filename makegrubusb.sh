#!/bin/bash


#---
# Script to make bootable usb sticks
#---



error() {
	echo "${0%%*/}: error: $1"
	exit 1
}




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

WHIPTAIL=dialog


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


sudo mount -t vfat ${USB_DISK}1 ${USB_MOUNT} || error "when mounting ${USB_DISK}1"

sudo grub-install --no-floppy --recheck --root-directory=${USB_MOUNT} ${USB_DISK} || error "on grub installation"

sudo cat <<EOF >> ${USB_MOUNT}/boot/grub/grub.cfg

set default="1"
set timeout=30
set color_normal=white/black
set color_highlight=white/light-gray

GRUB_GFXMODE=800x600x16
insmod vbe

menuentry "Chainload 1st Partition from 1st Hard Disk" {
set root=(hd0,1)
chainloader +1
}

menuentry "Load loopbacked iso (in /boot/iso)" {
  configfile autoiso.cfg
}

EOF

sudo cat <<EOF > ${USB_MOUNT}/boot/grub/autoiso.cfg


function loopback_iso_entry {
    realdev="$1"
    isopath="$2"
    loopdev="$3"

    if test -f /boot/grub/loopback.cfg; then
	cfgpath=/boot/grub/loopback.cfg
    elif test -f /grub/loopback.cfg; then
	cfgpath=/grub/loopback.cfg
    else
	return 1;
    fi

    echo loopback.cfg $isopath: yes
    menuentry "GRUB Loopback Config (${realdev}${isopath})" "$realdev" "$isopath" "$cfgpath" {
	set device="$2"
	set iso_path="$3"
	set cfg_path="$4"

	export iso_path
	loopback loopdev_cfg "${device}${iso_path}"
	set root=(loopdev_cfg)
	configfile $cfg_path
	loopback -d loopdev_cfg
    }
    return 0
}


for file in ${dev}${dir}/*.iso ${dev}${dir}/*.ISO; do
	if ! test -f "$file"; then continue; fi

	pathname $file isopath
	if test -z "$dev" -o -z "$isopath"; then continue; fi
	if ! loopback loopdev_scan "$file"; then continue; fi

	saved_root=$root
	set root=(loopdev_scan)

	loopback_iso_entry $dev $isopath (loopdev_scan)

	set root=$saved_root
	loopback -d loopdev_scan
done

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



