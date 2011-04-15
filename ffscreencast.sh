#!/bin/sh

START="-ss 00:05:00"
END="-t  00:10:00"

RATE="-r 25"
SCREEN="-s 1280x800"
#xrandr | grep "*" | cut  -f 4 -d " "

#CODEC="-acodec pcm_s16le -vcodec libx264 -vpre lossless_ultrafast"
CODEC="-acodec libvorbis -ab 128k -ac 2"


ffmpeg $START $END -f alsa -i pulse -f x11grab $RATE $SCREEN -i :0.0 $CODEC output.mkv
