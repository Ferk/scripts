#!/bin/bash
#
#

color16() {
    # prints a color table of 8bg * 8fg * 2 states (regular/bold)
    printf "Table for 16-color terminal escape sequences.\n\n"
    echo "Background | Foreground colors"
    echo "---------------------------------------------------------------------"
    for((bg=40;bg<=47;bg++)); do
	for((bold=0;bold<=1;bold++)) do
	printf "\033[0m"" ESC[${bg}m   | "
	for((fg=30;fg<=37;fg++)); do
	    if [ $bold == "0" ]; then
		printf "\033[${bg}m\033[${fg}m [${fg}m  "
	    else
		printf "\033[${bg}m\033[1;${fg}m [1;${fg}m"
	    fi
	done
	echo -e "\033[0m"
	done
	echo "--------------------------------------------------------------------- "
    done
    printf "\n\n"
}

color256() {
    cat <<EOF
Table for 256-color terminal escape sequences.
 To use as foreground: ESC[38;5;NUMBERm
 To use as background: ESC[48;5;NUMBERm

EOF
    ## Show colors
    for x in $( seq -w 0 255 )
    do
	printf "\033[38;5;${x}m${x}\033[00m \033[48;5;${x}m${x}\033[00m "
    done 
    printf "\n"
}

color256
color16
