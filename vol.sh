#!/bin/sh
#
#---
# Increases/decreases/(un)mutes the volume (uses pulseaudio)
#---

# Fernando Carmona Varo
#

# pulseaudio maximum volume multiplier
# Volume 65536 (0x10000) is normal max, greater values will amplify the audio signal (with clipping).
multiplier=3

percent=$1

if [ -z $percent ]
then
    echo "usage: vol.sh <+XX|-XX|mute>"
    exit
fi

if ! pulseaudio --check &>/dev/null
then
    echo "pulseaudio not running"
    exit
fi

if [ "$1" = "mute" ] # toggle mute
then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    exit
fi


current_vol=$(pacmd dump | awk '/set-sink-volume/ { print $3; exit }')

if [ "$current_vol" ]
then

    max=$((multiplier * 0x10000))

    set_vol=$((current_vol + (percent * max/100)))
    #set_vol=$((current_vol + (percent * 100)))


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
    display_vol=$((set_vol * 300/max))

    pactl set-sink-volume @DEFAULT_SINK@ -- $set_vol

    # notify with osd if available
    hash osd_cat 2>$- && {
	pkill osd_cat
	osd_cat -O 3 -o 12 -c white -A center -d 1 -f "-*-*-*-*-*-*-*-*-*-*-*-*-*" \
	    -b percentage -P $percent -T $(bc <<<"$set_vol/$((0x100))")
    } &

else
    echo "Couldn't get current volume!"
    display_vol="${percent}%"
    pactl set-sink-volume @DEFAULT_SINK@ -- ${percent}%
fi

# notify about the volume change in dwm
xsetroot -name "volume: $display_vol" && sleep 1 && dwm.sh update &

echo $display_vol
