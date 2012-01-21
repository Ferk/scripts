#!/bin/bash

## Script to record a screencast

# give me one moment to prepare myself
echo "** Screencast recording initiating..."
echo "** press q or issue \"pkill ffmpeg\" for exiting"
sleep 1

END="-t  0:30:00" # 

FNAME="screencast-$(date +%m%d-%H%M).avi"

SCRSIZE=$(xrandr | grep "*")
SCRSIZE=$(echo $SCRSIZE | cut -f 1 -d " ")

#RATE="-r 15"
SCREEN="-s $SCRSIZE"
#xrandr | grep "*" | cut  -f 4 -d " "

#CODEC="-acodec pcm_s16le -vcodec libx264"
CODEC=" -b:a 64k -b:v 256k"
#CODEC="-acodec libvorbis -b:a 64k -b:v 256k"

# Record from microphone
A_IN="-f pulse -i default"
# Record from system output
A_IN="-f pulse -i 0"

#ffmpeg -f alsa -i pulse -f x11grab -s 1024x600 -r 24 -b 100k -bf 2 -g 300 -i :0.0 -ar 22050 -ab 64k -acodec libmp3lame output.mpg

ffmpeg $START $END $A_IN -loglevel info -f x11grab $RATE $SCREEN -i :0.0 $CODEC $@ "$FNAME"

notify-send "${0%%*/}" "Recording finished ($FNAME)"
echo -e "** Video saved as \e[33m\"$FNAME\"\e[0m"
