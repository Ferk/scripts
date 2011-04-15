#!/bin/sh

if [ $1 -z ]
then
	DELAY=1000
else
	DELAY="$*"
fi

while true
do
    echo "ButtonPress 5 ButtonRelease 5" | xmacroplay -d $DELAY
done