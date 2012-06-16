#!/bin/sh
#
# Captures from the camera and changes the brightness of the
# screen backlight according to the brightness level of the
# image captured by the cam.
#
# Uses ffmpeg, imagemagick, xbacklight and acpi
#

# Time for the camera to capture
TIMECK=0.05

# Minimal % for a change to be made
TOLERANCE=5

# Maximal % to change (smaller means smoother)
TOP=10

# Limits in brightness level detected
UPPER=35
LOWER=10

acpi -a | grep "off-line" && { # change limits if on battery
    UPPER=60
    LOWER=30
}

# This makes it easier for the script to be run by cron
[ -z $DISPLAY ] && export DISPLAY=:0

IMG=$(mktemp --suffix=.jpg)
ffmpeg -loglevel error -f video4linux2  -i /dev/video0 -r  $TIMECK  -t  $TIMECK  "$IMG" || exit $?
BRIGHT=$(convert "$IMG"  -format "%[fx:100*mean]" info:)

echo "Brightness detected: ${BRIGHT}%"

[ ${BRIGHT%.*} -lt $LOWER ] && {
    LIGHT=0
} || { 
    [ ${BRIGHT%.*} -gt $UPPER ] && {
	LIGHT=100
    } || {
	LIGHT=$(( ${BRIGHT%.*}*(100/UPPER) ))
    }
}
LIGHT=${LIGHT%%.*}

DIFF=$(($(xbacklight -get | cut -f1 -d.) - $LIGHT))

[ $DIFF -gt $TOP ] && DIFF=$TOP

[ $DIFF -gt $TOLERANCE -o $DIFF -lt -$TOLERANCE ] && {
    echo Setting backlight to $LIGHT
    xbacklight -set ${LIGHT%%.*} -time 3000
}

rm "$IMG"
