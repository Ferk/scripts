#!/bin/sh
#
# Convert files to some preferred open formats.
# eg. video files to webm
#
# by Fernando Carmona Varo
#

help() {
    echo "usage: ${0##*/} <file(s)>"; 
}

[ "$1" ] || { help; exit 0;}

#bitrate="-b:a 128k -b:v 512k"
bitrate="-b:a 64k "


while [ "$1" ]; do
    fname="$1"
    shift

    [ -f "$fname" ] || { echo "file doesn't exist: $fname"; exit 1;}

    fext=${fname##*.}

    echo "converting $fname"
    case $fext in
        avi|mp4|wmv|mkv)
            ffmpeg -i "$fname" $bitrate "${fname%.*}.webm"
            ;;
        png|jpg)
	    [ -e "${fname%.*}.webp" ] || \
            cwebp -quiet -m 6 "$fname" -o "${fname%.*}.webp"
            ;;
	ogg)
	    ;;
        *)
            echo "no conversion available for format \"${fext}\": $fname"
    esac || {
        echo "Error in conversion of ${fname}"
        exit 2
    }

done
