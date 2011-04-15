#!/bin/sh


tempchk () {
    TEMP=$(sensors | grep -o -e "+....°C")
    NTEMP=$(echo "$TEMP" | cut -c "2-3")

    for i in $NTEMP
    do
        if [ $i -gt 80 ]
        then
            #notify-send "DANGER!! High temp ($TEMP)" -u critical -i dialog-warning  -h string:synchronouns:"tempsensor"
            notify-send "DANGER!! High temp ($TEMP)" -u critical -i "/usr/share/icons/Tango/32x32/status/dialog-warning.png" -h string:synchronouns:"tempsensor"
        fi
    done
}


if [ "$#" -eq "0" ]
then
    tempchk
    echo $TEMP
else
    if [ "$1" = "-d" ]
    then
        while true
        do
            tempchk
            sleep 60
        done &
        echo "Daemon started"
    else
        echo "usage: checktemp [-d]"
    fi
fi



