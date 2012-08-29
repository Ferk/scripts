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

    # get file extension in lowercase
    fext=$( echo ${fname##*.} | tr '[A-Z]' '[a-z]' )

    echo "converting $fname"
    case $fext in
        avi|mp4|wmv|mkv)
	    dest="${fname%.*}.webm"
	    [ -e dest ] && { echo "destination file already exists: $dest"; exit 1;}
            ffmpeg -i "$fname" $bitrate "$dest"
            ;;
        png|jpg)
	    dest="${fname%.*}.webp"
	    [ -e dest ] && { echo "destination file already exists: $dest"; exit 1;}
            cwebp -quiet -m 6 "$fname" -o "$dest"
            ;;
	ogg)
	    ;;
        *)
            echo "no conversion available for format \"${fext}\": $fname"
    esac || {
	errors="$errors ${fname}\n"
    }

done

if [ "$errors" ]
then
    echo "Errors were found in the following files and they were not converted:"
    echo -e "$errors"
fi

