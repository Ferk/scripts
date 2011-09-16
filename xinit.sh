#!/bin/sh

# Only run this script once (checking if some main process is active)
if ps ax | grep -v grep | grep xbindkeys > /dev/null
then
	echo "xinit.sh: already running processes"
    exit
else
	echo "** Running xinit.sh script"
fi

# wm-agnostic keyboard bindings
xbindkeys &

# Adjust color temperature of the screen according to the position of the sun
redshift &

# Run emacs daemon, so the clients start instantly
#emacs --daemon &

# Reminders for taking breaks
#xwrits clock breakclock typetime=50 &

dbus-launch &
gnome-settings-daemon &
eval $(gnome-keyring-daemon --start --components=secrets) &

gnome-power-manager &

# gnome-volume-control-applet &

# nm-applet &

export LANG="es_ES.utf8"
setxkbmap es

# system beep [volume] [pitch] [duration]
xset b 10 100 2000
xset b 0


## Set up soundmixer start values
amixer sset Master 50% on
amixer sset PCM 100% on
amixer sset Front 100% on
amixer sset Headphone 100% on

## Temperature & battery checking
statck -d &

## Automatically suspend when computer is idle
idlescript.sh > idlescript.log &

###
setwallpaper &
t &
browser &
exit
