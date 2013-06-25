#!/bin/sh

#----
# Wrapper to execute the default terminal
# (defined by XTERM variable, which I set in my ~/.profile).
#
# Also, any args received will be executed in a subshell in the
# terminal, pausing when the exit code is not standard (error).
#----


XTERM=${XTERM:-"xterm"}

if [ -z "$1" ]
then
    $XTERM
else
    $XTERM -e ${SHELL:-bash} -c "{ $@ ;} && { echo -e '\n\e[32mExiting...';sleep 2;} || { echo -e '\n\e[31mPress any key to close...';read -sn 1;}"
fi


