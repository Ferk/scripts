#!/bin/sh

# Fernando Carmona Varo

##
# Wrapper script around my dwm
##

# Loop to update the status info in the bar
while true
do
    TIME=$(date '+%a %F --%H:%M--')
    LOAD=$(uptime | sed 's/.*, //')

    #BAT=$(acpi -b | cut -d, -f 2)
    STAT=$(statck -1)
    TRAFIC=$(vnstat --oneline | cut -d ";" -f 11)

    #xsetroot -name "$TIME {$STAT} <$LOAD> -$TRAFIC-"
    xsetroot -name "^[f3;$TIME ^[f2;^[i2;^[f0;$STAT^[i29; ^[f77F;$LOAD^[i15; ^[f292;^[i35;$TRAFIC "
    sleep 40
done &

#trayer --expand true --widthtype request --transparent true --alpha 255 --edge top --align right --height 15 &
#trayer &

# Set a known name to the WM so that some programs don't complain
if hash wname; then wmname LG3D
else xprop -root -f _NET_WM_NAME 8s -set _NET_WM_NAME "LG3D"
fi

# Run dwm in loop so it can restart (to close session pkill dwm.sh)
while [ 1 ]
do
    ~/bin/dwm/dwm
done
