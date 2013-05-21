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

delay=${1:-100}

while true
do
    printf "ButtonPress 1\nDelay 1\nButtonRelease 1" | xmacroplay -d $delay
done
