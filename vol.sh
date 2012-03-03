#!/bin/sh
#
# Increases/decreases/(un)mutes the volume (uses pulseaudio)
#
# Fernando Carmona Varo
#

# pulseaudio maximum volume value
# Volume 65536 (0x10000) is normal max, greater values will amplify the audio signal (with clipping).
max=0x30000

percent=$1

if [ -z $percent ]
then
    echo "usage: vol.sh <+XX|-XX|mute>"
    exit
fi

if [ "$1" = "mute" ] # toggle mute
then
    if pacmd dump | grep "set-sink-mute .* yes" > /dev/null
    then
        pactl set-sink-mute 0 0 # unmute
    else
        pactl set-sink-mute 0 1 # mute
    fi
    exit
fi


current_vol=$(pacmd dump | awk '/set-sink-volume/ { print $3; exit }')

set_vol=$((current_vol + (percent * max/100)))


if [ $((set_vol)) -lt $((0x0)) ]
then
    echo "Volume can't be set lower"
    set_vol=$((0x0))
else
    if [ $((set_vol)) -gt $((max)) ]
    then
        echo "Volume can't be set higher"; exit
        set_vol=$((max))
    fi
fi

pactl set-sink-volume 0 $set_vol

display_vol=$((set_vol * 100/max))

# notify about the volume change in dwm
xsetroot -name "volume: $display_vol" && sleep 1 && dwm.sh update &

# notify with osd if available
hash osd_cat 2>$- && {
    pkill osd_cat
    osd_cat -O 3 -o 12 -c white -A center -d 1 -f "-*-*-*-*-*-*-*-*-*-*-*-*-*" \
	-b percentage -P $display_vol
} &

echo $display_vol
