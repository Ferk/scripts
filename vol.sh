#!/bin/sh


# maximum value 
# Volume 65536 (0x10000) is normal volume, values greater than this amplify the audio signal (with clipping).
max=0x20000

percent=$1

if [ -z $percent ]
then
    echo "usage: vol.sh [+XX|-XX|mute]"
    exit
fi

if [ "$1" == "mute" ] # toggle mute
then
    if pacmd dump | grep set-sink-mute | grep yes > /dev/null
    then
	pactl set-sink-mute 0 0 # unmute
    else
	pactl set-sink-mute 0 1 # mute
    fi
    exit
fi


current_vol=`pacmd dump | grep "set-sink-volume alsa_output.pci-0000_00_1b.0.analog-stereo" | cut -d " " -f 3`

set_vol=$((current_vol + (percent * max/100)))


if [ $((set_vol)) -lt $((0x0)) ]
then
	echo "Volume can't be set lower"
	exit
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


# set the proper icon fot the notification
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



notify-send "$display_vol% volume" -t 600 -i $icon_name -h int:value:$display_vol

echo $display_vol

