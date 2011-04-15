#!/bin/sh

# Fernando Carmona Varo

# Performs a lot of clicks pretty fast in an endless loop. It can drive you crazy
# if you execute it unprepared. I just made it for fun, and beating those silly flash
# games about "how fast can you click?"
#
# You can activate/deactivate it by binding a key shortcut to..
# :    pkill turboclick.sh || turboclick.sh
#
# You need xmacro installed.

# usage: autoscroll.sh [miliseconds]

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
