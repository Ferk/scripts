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

while true
do
    echo "ButtonPress 1 ButtonRelease 1" | xmacroplay -d 10
done
