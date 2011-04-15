#!/bin/sh

echo "usage: vol.sh [+XX|-XX]"

percent=$1

current_vol=`pacmd dump | grep "set-sink-volume alsa_output.pci-0000_00_1b.0.analog-stereo" | cut -d " " -f 3`

set_vol=$((current_vol + (percent * 0x10000/100)))

if [ $(($set_vol)) -gt $((0x10000)) ]
then
    set_vol=$((0x10000))
else
    if [ $(($set_vol)) -lt $((0x0)) ]
    then
        set_vol=$((0x0))
    fi
fi


pactl set-sink-volume 0 $(printf "0x%X" $set_vol)

display_vol=$(echo "100*$set_vol/$((0x10000))" | bc)

if [ "$icon_name" = "" ]
then
    if [ "$display_vol" = "0" ]
    then
        icon_name="audio-volume-muted"
    else
        if [ "$display_vol" -lt "33" ]
        then
            icon_name="audio-volume-low"
        else
            if [ "$display_vol" -lt "67" ]
            then
                icon_name="audio-volume-medium"
            else
                icon_name="audio-volume-high"
            fi
        fi
    fi
fi

notify-send "$display_vol% volume" -i $icon_name -h int:value:$display_vol -h string:synchronous:volume

