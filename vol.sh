#!/bin/sh

percent=$1

if [ -z $percent ]
then
    echo "usage: vol.sh [+XX|-XX]"
    exit
fi

current_vol=`pacmd dump | grep "set-sink-volume alsa_output.pci-0000_00_1b.0.analog-stereo" | cut -d " " -f 3`

set_vol=$((current_vol + (percent * 0x10000/100)))


if [ $((set_vol)) -lt $((0x0)) ]
then
	echo "Volume can't be set lower"
	exit
    set_vol=$((0x0))
else 
	if [ $((set_vol)) -gt $((0x10000)) ]
	then
		echo "Volume can't be set higher"
		exit
		set_vol=$((0x10000))
	fi
fi

pactl set-sink-volume 0 $set_vol

display_vol=$((set_vol*100/0x10000))


# Elegir el icono adecuado para la notificación
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

notify-send "$display_vol% volume" -t 600 -i $icon_name -h int:value:$display_vol -h string:synchronous:volume
echo $display_vol

