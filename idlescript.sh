#!/bin/sh

# Fernando Carmona Varo <ferkiwi@gmail.com

#---
# Keeps waiting until there's a lapse of time with prolonged
# inactivity from user and system, and sets the computer to suspend
# status.
#
# I wrote this script because most other suspend-on-idle methods don't
# take HD activity into account, which is required when you let the
# computer alone working on some operation, and want it to
# automatically suspend when the operation is finished.
#
# If you want the computer to wake up automatically at some given time
# you can use the command: rtcwake -t <time>
#
# Requires pm-utils and xprintidle
#---

## Variables

# Timeout in seconds
TIMEOUT=$((15*60))
# Disk I/O time to be considered inactive, in milliseconds
IOLIMIT=$((TIMEOUT*1000 * 2/100 ))

printf " Timeout:%7d.000 s\n HDLimit:%10d ms\n"  $TIMEOUT $IOLIMIT

## Script

[ $DISPLAY ] || export DISPLAY=":0"

# zeroing these means the first record would be higher, but that doesn't matter
HD0=0
while true
do
    sleep $TIMEOUT

    # weighted milliseconds the Disks spent doing I/Os
    HD1=$(cat /sys/block/*/stat | awk '{ a += $11 } END {print a}')
    
    printf "[$(date +'%F %H:%M')] Activity:  HD:%7d\n" $(($HD1-$HD0)) $((KB1-KB0))

    # Actions to activate when the Hard Disk is inactive and no user input
    [ $(($HD1-$HD0)) -lt $IOLIMIT ]  && [ "$(xprintidle)" -ge $(("$TIMEOUT"*1000)) ] && { 
	echo "Lower than the $IOLIMIT limit. Suspending!!"
	
	if [ "$DISPLAY" ]
	then
	    xmessage "Computer has been idle, will go into sleep mode automatically" -
	else
            systemctl suspend
	fi
    }

    HD0=$HD1
done
