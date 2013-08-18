#!/bin/sh

# Fernando Carmona Varo <ferkiwi@gmail.com>

#----
# Tool for listing the top CPU-consuming running processes
# it accepts a regexp argument to be specific.
#----

# Use first argument as regexp to get the processes
if [ $1 ]; then
    cmd="ps u -p "
    PIDs=$(pgrep $@)
    [ $? != 0 ] || [ -z "$PIDs" ] && exit
    for i in $PIDs; do
	cmd="${cmd}${i},"
    done
    cmd=${cmd%,} # remove last ","
else
    cmd="ps aux"
fi


# Remove header
cmd="$cmd | tail -n +2"

# cut the lines that are too long
[ $COLUMNS ] || COLUMNS=$(tput cols)
cmd="$cmd | cut -c -$COLUMNS"
# sort them according to the 3rd field (CPU)
cmd="$cmd | sort -rk3"

# only show top 10
cmd="$cmd | head -10"

# Print header and command output
[ $TERM != dumb ] && {
    H="\e[32m"
    S="\e[33m"
    T="\e[0m"
}
printf "$cmd\n${H}USER       PID ${S}%%CPU${H} %%MEM    VSZ   RSS TTY      STAT START   TIME COMMAND${T}\n"
eval $cmd


