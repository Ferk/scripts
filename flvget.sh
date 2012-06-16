#!/bin/sh

cd ~/.cache/chromium/Default/Cache/

VIDEOS=$(file * | grep Video | cut -f 1 -d:)

for i in $VIDEOS
do
    echo "Found video file: $i"
    mplayer $i > /dev/null 2> /dev/null
    echo "R(emove)?"
    read action
    if [ r == $action -o R == $action ]
    then
        echo "Borrando \"$i\"..."
        rm $i
    fi
done

echo $VIDEOS
