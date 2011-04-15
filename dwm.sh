#!/bin/sh

# Loop to update the status info in the bar
while true
do
    TIME=$(date '+%a %F --%H:%M--')
    LOAD=$(uptime | sed 's/.*,//')

    #BAT=$(acpi -b | cut -d: -f 2)
    BAT=$(acpi -b | cut -d, -f 2)

    xsetroot -name "$TIME ·$BAT· <$LOAD>"
    sleep 30
done &

# systray
#trayer --expand true --widthtype request --transparent true --alpha 255 --edge top --align right --height 15 &
trayer &

# Run dwm in loop so it can restart (to close session pkill dwm.sh)
while [ 1 ]
do
    ~/bin/dwm/dwm
done
