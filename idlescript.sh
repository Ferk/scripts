#!/bin/sh
#
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
# keyboard interruptions
KB0=$(cat /proc/interrupts | awk '/i8042/ {print $2; exit}')
while true
do
    sleep $TIMEOUT

    HD1=$(cat /sys/block/sda/stat | awk '{print $11}')
    KB1=$(cat /proc/interrupts | awk '/i8042/ {i += $2+$3}; END { print i }')
    
    echo "[$(date +%F_%H%M)] Activity:  HD:$(($HD1-$HD0)) Keyboard:$((KB1-KB0))"

    # Actions to activate when the Hard Disk is inactive and no user input
    [ $(($HD1-$HD0)) -lt $IOLIMIT ]  && [ $((KB1-KB0)) = 0 ] && { 
	echo "Lower than the $IOLIMIT limit. Suspending!!"
        sudo pm-suspend
    }

    HD0=$HD1
    KB0=$KB1
done
