#!/bin/sh

#---
# This script is called from my .xinitrc at the start of my X.org session,
# before launching the WM.
#---


# Launch the given command asynchronously, if it's available
xinit_run() {
    hash "${@%% *}" && eval "$@" &
}

# Only run this script once (checking if some main process is active)
if pgrep xbindkeys >/dev/null
then
	echo "xinit.sh: already running processes"
	return || exit
else
	echo "** Running xinit.sh script"
fi


# wm-agnostic keyboard bindings
xinit_run xbindkeys

# Adjust color temperature of the screen according to the position of the sun
xinit_run redshift

xinit_run dbus-launch

# gnome-settings-daemon && eval $(gnome-keyring-daemon --start --components=secrets) &
# gnome-power-manager &
# gnome-volume-control-applet &
# nm-applet &

setxkbmap de

# Disable access control so any user can use the DISPLAY
xinit_run "xhost +"

# xbacklight utility to control screen backlight
xinit_run "xbacklight = 0"

# system beep [volume] [pitch] [duration(ms)]
xset b 2 1 200

# # synchronize the primary selection and clipboard buffers
# autocutsel -selection PRIMARY -fork
# autocutsel -selection CLIPBOARD -fork

# Activate Control+Alt+Backspace to kill X server
setxkbmap -option terminate:ctrl_alt_bksp

xrdb ~/.Xdefaults

## Set up sound and mixer start values
if hash pulseaudio
then
    start-pulseaudio-x11
    pactl set-sink-volume 0 0x05000 # 0x10000 == 100%
elif hash amixer
then
    amixer sset Master 50% on
    amixer sset PCM 100% on
    amixer sset Front 100% on
    amixer sset Headphone 100% on
fi

# ## Temperature & battery checking
# statck -d &

## Automatically suspend when computer is idle
xinit_run "idlescript.sh > idlescript.log"

# disable the touchpad tapping when typing
xinit_run "syndaemon -t -k -i 2 -d"

# enable video acceleration in ATI cards
export LIBVA_DRIVER_NAME=vdpau
export VDPAU_DRIVER=r600

###
xinit_run setwallpaper
xinit_run t
xinit_run browser

unset xinit_run
