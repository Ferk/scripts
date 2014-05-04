#!/bin/sh
#
#---
# Increases/decreases/(un)mutes the volume (uses pulseaudio)
#---

# Fernando Carmona Varo
#

# Volume 65536 (0x10000) is normal max, greater values will amplify the audio signal (with clipping).
# A multiplier can be specified here
multiplier=3

percent=$1

if [ -z $percent ]
then
    echo "usage: vol.sh <+XX|-XX|mute>"
    exit
fi

if [ "$1" = "mute" ] # toggle mute
then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    exit
 fi

default_sink=$(pacmd dump | sed -n 's/set-default-sink \(.*\)/\1/p')
current_vol=$(pacmd dump | sed -n "s/set-sink-volume $default_sink \(.*\)/\1/p")

if [ "$current_vol" ]
then

    # Don't apply multiplier when volume is less than 100%
    if [ $((current_vol*100/0x10000)) -lt 100 ]
    then
	max=$((0x10000))
    else
	max=$((multiplier * 0x10000))
    fi

    set_vol=$((current_vol + (percent * max/100)))
    #set_vol=$((current_vol + (percent * 100)))


    if [ $((set_vol)) -lt $((0x0)) ]
    then
	echo "Volume can't be set lower"
	set_vol=$((0x0))
    elif [ $((set_vol)) -gt $((max)) ]
    then
        echo "Volume can't be set higher"
        set_vol=$((max))
    fi

    [ "$set_vol" = "$current_vol" ] && exit
    
    display_vol=$((set_vol * multiplier * 100/max))

    pactl set-sink-volume @DEFAULT_SINK@ -- $set_vol

    # notify with osd if available
    hash osd_cat 2>$- && {
	pkill osd_cat
	osd_cat -O 3 -o 12 -c white -A center -d 1 -f "-*-*-*-*-*-*-*-*-*-*-*-*-*" \
	    -b percentage -P $((set_vol * 100/max)) -T $((set_vol*100/0x10000))
    } &

else
    echo "Couldn't get current volume!"
    display_vol="${percent}%"
    pactl set-sink-volume @DEFAULT_SINK@ -- ${percent}%
fi

# notify about the volume change in dwm
xsetroot -name "volume: $display_vol" && sleep 1 && dwm.sh update &

echo $display_vol

