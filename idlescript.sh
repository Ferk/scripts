#!/bin/sh
#
# Keeps waiting until there's a lapse of time with prolonged
# inactivity from user and system, and sets the computer to suspend
# status.
#
# Requires pm-utils
#
# by Fernando Carmona Varo
#

# Timeout in seconds
TIMEOUT=$((10*60))

# I/O milliseconds limit to be considered inactive
IOLIMIT=4000

# weighted milliseconds the HD spent doing I/Os
HD0=$(cat /sys/block/sda/stat | awk '{print $11}')
while true
do
    sleep $TIMEOUT

    HD1=$(cat /sys/block/sda/stat | awk '{print $11}')
    
    echo "[$(date +%F_%H%M)] HD Usage: $(($HD1-$HD0))"

    # Actions to activate when the Hard Disk is inactive and no user input
    [ $(($HD1-$HD0)) -lt $IOLIMIT ]  && [ $(xprintidle) -gt ${TIMEOUT}000 ] && { 
	echo Lower than the $IOLIMIT limit. Suspending!! 
        sudo pm-suspend
    }

    HD0=$HD1
done
