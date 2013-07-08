#!/bin/bash

# Fernando Carmona Varo

#---
# Wrapper script around my dwm window manager
#---


BUILDIR="$XDG_CONFIG_HOME/dwm/"

[ "$DISPLAY" ] || { echo "error: no DISPLAY available"; exit 1; }

# Update the status info in the bar
statusupd() {
    TIME=$(date '+%a %F --%H:%M--')
    LOAD=$(uptime | sed 's/.*, //')
    
    #BAT=$(acpi -b | cut -d, -f 2)
    STAT=$(statck -1)
    #TRAFIC=$(vnstat --oneline | cut -d ";" -f 11)

    # # check if my neightbor is connected
    # HOSTS=""
    # for h in 1
    # do
    # 	ping -c 1 "192.168.1.$h" && HOSTS="${HOSTS}.$h"
    # done
 
    # # use reduced traffic speed if it's connected
    # if [ $(echo $HOSTS | wc -c) -gt 3 ]
    # then
    # 	transmission-remote --alt-speed
    # else
    # 	transmission-remote --no-alt-speed
    # fi

    # number of ARP entries
    HOSTS=$(arp -a | wc -l)
    
    xsetroot -name "$TIME {$STAT} <$LOAD> ☯$HOSTS"
        #xsetroot -name "^[f3;$TIME ^[f2;^[i2;^[f0;$STAT^[i29; ^[f77F;$LOAD^[i15; ^[f292;^[i35;$HOSTS "
}

[ "$1" = "update" ] && {
    statusupd
    exit
}

while true
do
    statusupd
    sleep 40
done &

# if dwm is already running, only spawn status updater
pgrep "dwm$" >/dev/null && {
    echo "dwm is already running, a status update daemon has been spawned, but dwm won't be re-run"
    exit
}

# Set a known name to the WM so that some programs don't complain
if hash wmname >/dev/null 2>&1
then 
    wmname LG3D
else 
    xprop -root -f _NET_WM_NAME 8s -set _NET_WM_NAME "LG3D"
fi

# Run dwm in loop so it can restart (to close session pkill dwm.sh)
while true
do
    # Compile dwm if newer config is available
    if [ "$BUILDIR/config.h" -nt "$BUILDIR/dwm"  ]
    then
	( cd "$BUILDIR" && make )
    fi

    # Run custom dwm if it exists (even if compilation failed)    
    if [ -e "$BUILDIR/dwm"  ]
    then
	"$BUILDIR/dwm"
    else 
	dwm
    fi
done


