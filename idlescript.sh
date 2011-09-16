#!/bin/bash

# segundos de timeout
TIMEOUT=$((15*60))

# maximum I/O milliseconds
IOLIMIT=1000

# weighted milliseconds the HD spent doing I/Os
HD0=$(cat /sys/block/sda/stat | awk '{print $11}')
while true
do
    sleep $TIMEOUT

    [ $(xprintidle) -gt ${TIMEOUT}000 ] || continue
    # no user input detected in 10 min


    HD1=$(cat /sys/block/sda/stat | awk '{print $11}')
    
    echo "HD Usage: $(($HD1-$HD0))"

    # Activate suspension when the Hard Disk is inactive
    [ $(($HD1-$HD0)) -gt $IOLIMIT ] || sudo pm-suspend

    HD0=$HD1
done

