#!/bin/sh
#
# Wrapper to execute the default terminal
# (defined by XTERM variable, which I set in my ~/.profile).
#
# Also, any args received will be executed in a subshell in the
# terminal, pausing when the exit code is not standard (error).
#

SH="bash"
[ -z $XTERM ] && TERM="xterm"

if [ -z $@ ]
then
    $XTERM
else
    $XTERM -e $SH -c "if { $@ ;}; then echo -e '\n\e[32mExiting...'; sleep 2; else echo -e '\n\e[31mEnter to close..'; read ; fi"
fi


