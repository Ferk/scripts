#!/bin/sh

if ps ax | grep -v grep | grep nm-applet > /dev/null
then
    exit
fi


gnome-settings-daemon
eval $(gnome-keyring-daemon --start --components=secrets)

nm-applet &
gnome-power-manager &


# gnome-volume-control-applet &

nm-applet &


## Set up soundmixer start values
amixer sset Master 50% on
amixer sset PCM 100% on
amixer sset Front 100% on
amixer sset Headphone 100% on

## Temperature checking
checktemp.sh -d &

setwallpaper &
term &
exit