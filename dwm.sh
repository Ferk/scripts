#!/bin/sh

# Fernando Carmona Varo

##
# Wrapper script around my dwm window manager instalation
##

# Loop to update the status info in the bar
while true
do
    TIME=$(date '+%a %F --%H:%M--')
    LOAD=$(uptime | sed 's/.*,//')

    #BAT=$(acpi -b | cut -d, -f 2)
    STAT=$(statck -1)

    xsetroot -name "$TIME {$STAT} <$LOAD>"
    sleep 30
done &

#trayer --expand true --widthtype request --transparent true --alpha 255 --edge top --align right --height 15 &
trayer &

# Set a known name to the WM so that some programs don't complain
wmname LG3D

# Run dwm in loop so it can restart (to close session pkill dwm.sh)
while [ 1 ]
do
    ~/bin/dwm/dwm
    #wmii
done
