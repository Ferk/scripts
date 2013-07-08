#!/bin/sh

# Fernando Carmona Varo

#---------
# Slowly scrolls down with the mouse automatically, so you can read a webpage,
# a book, or whatever you want to read on your PC.
# Useful when you have your hands busy when eating or doing something.
#
# You can activate/deactivate it by binding a key shortcut to..
#:    pkill autoscroll.sh || autoscroll.sh
#
# You need xmacro installed.
#--------

# usage: autoscroll.sh [miliseconds]

DELAY=${1:-1000}

while true
do
    echo "ButtonPress 5 ButtonRelease 5" | xmacroplay -d $DELAY
done
