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
# Requires pm-utils
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
KB0=0
while true
do
    sleep $TIMEOUT

    # weighted milliseconds the Disks spent doing I/Os
    HD1=$(cat /sys/block/*/stat | awk '{ a += $11 } END {print a}')
    # keyboard interruptions
    KB1=$(cat /proc/interrupts | awk '/i8042/ {i += $2+$3}; END { print i }')
    
    printf "[$(date +'%F %H:%M')] Activity:  HD:%7d Keyboard:%6d\n" $(($HD1-$HD0)) $((KB1-KB0))

    # Actions to activate when the Hard Disk is inactive and no user input
    [ $(($HD1-$HD0)) -lt $IOLIMIT ]  && [ $((KB1-KB0)) = 0 ] && { 
	echo "Lower than the $IOLIMIT limit. Suspending!!"
        sudo pm-suspend
    }

    HD0=$HD1
    KB0=$KB1
done
