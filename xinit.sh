#!/bin/sh

# Only run this script once (checking if some main process is active)
if pgrep xbindkeys >&-
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

# gnome-settings-daemon && eval $(gnome-keyring-daemon --start --components=secrets) &
# gnome-power-manager &
# gnome-volume-control-applet &
# nm-applet &

setxkbmap es

# Disable access control so any user can use the DISPLAY
xhost +

# system beep [volume] [pitch] [duration]
xset b 10 100 2000
#xset b 0

# # synchronize the primary selection and clipboard buffers
# autocutsel -selection PRIMARY -fork
# autocutsel -selection CLIPBOARD -fork

# Activate Control+Alt+Backspace to kill X server
setxkbmap -option terminate:ctrl_alt_bksp

## Set up sound and mixer start values
hash pulseaudio 2>&- && {
    start-puleaudio-x11
    pactl set-sink-volume 0 0x05000 # 0x10000 == 100%
} || {
    amixer sset Master 50% on
    amixer sset PCM 100% on
    amixer sset Front 100% on
    amixer sset Headphone 100% on
}

# ## Temperature & battery checking
# statck -d &

## Automatically suspend when computer is idle
idlescript.sh > idlescript.log &

# disable the touchpad tapping when typing
syndaemon -t -k -i 2 -d &

# checkgmail &

###
setwallpaper &
t &
browser &
exit
