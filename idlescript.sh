#!/bin/sh
#
# Keeps waiting until there's a lapse of time with prolonged
# inactivity from user and system, and sets the computer to suspend
# status.
#
# Requires pm-utils, xprintidle
#
# by Fernando Carmona Varo
#

## Variables

# Timeout in seconds
TIMEOUT=$((10*60))
# Disk I/O time to be considered inactive, in milliseconds
IOLIMIT=$((TIMEOUT*1000 * 20/100 ))

echo "Limit: $IOLIMIT"

## Script

[ $DISPLAY ] || export DISPLAY=":0"

# weighted milliseconds the HD spent doing I/Os
HD0=$(cat /sys/block/sda/stat | awk '{print $11}')
KB0=$(cat /proc/interrupts | awk '/i8042/ {print $2; exit}')
while true
do
    sleep $TIMEOUT

    HD1=$(cat /sys/block/sda/stat | awk '{print $11}')
    KB1=$(cat /proc/interrupts | awk '/i8042/ {i += $2+$3}; END { print i }'
    
    echo "[$(date +%F_%H%M)] HD Usage: $(($HD1-$HD0))"

    echo "keys: $((KB1-KB0))"

    # Actions to activate when the Hard Disk is inactive and no user input
    [ $(($HD1-$HD0)) -lt $IOLIMIT ]  && [ $(xprintidle) -gt ${TIMEOUT}000 ] && { 
	echo "Lower than the $IOLIMIT limit. Suspending!!"
        sudo pm-suspend
    }

    HD0=$HD1
    KB0=$KB1
done
