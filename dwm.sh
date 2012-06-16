#!/bin/sh

# Fernando Carmona Varo

##
# Wrapper script around my dwm
##


    # Update the status info in the bar
    statusupd() {
        TIME=$(date '+%a %F --%H:%M--')
        LOAD=$(uptime | sed 's/.*, //')

        #BAT=$(acpi -b | cut -d, -f 2)
        STAT=$(statck -1)
        #TRAFIC=$(vnstat --oneline | cut -d ";" -f 11)

	# check if my neightbor is connected
	HOSTS=""
	for h in 4 3 2
	do
	    ping -c 1 "192.168.1.$h" && HOSTS="${HOSTS}.$h"
	done
	# use reduced traffic speed if it's connected
	if [ $(echo $HOSTS | wc -c) -gt 3 ]; then
	    transmission-remote --alt-speed
	else
	    transmission-remote --no-alt-speed
	fi

        #xsetroot -name "$TIME {$STAT} <$LOAD> -$TRAFIC-"
        xsetroot -name "^[f3;$TIME ^[f2;^[i2;^[f0;$STAT^[i29; ^[f77F;$LOAD^[i15; ^[f292;^[i35;$HOSTS "
    }

    [ "$1" = "update" ] && {
        statusupd
        exit
    }
    [ "$1" = "daemon" ] && {
	while true
	do
	    statusupd
	    sleep 40
	done &
	#exit
    }

    # Set a known name to the WM so that some programs don't complain
    if hash wname; then wmname LG3D
    else xprop -root -f _NET_WM_NAME 8s -set _NET_WM_NAME "LG3D"
    fi


# Run dwm in loop so it can restart (to close session pkill dwm.sh)
while [ 1 ]
do
    ~/bin/dwm/dwm
done
