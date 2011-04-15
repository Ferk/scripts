#!/bin/bash

#emacs $@
#exit

OPT="-c -a \"\" "

# choose the emacs snapshot version if present
if [ -e /usr/bin/emacs-snapshot ]
then
    EC="emacsclient.emacs-snapshot"
    E="emacs-snapshot "
else
    EC="emacsclient"
    E="emacs"
fi

# When executed in terminal, use the terminal emacs
case "$TERM" in
    xterm*|rxvt*)
        #OPT="$OPT -nw"
        ;;
    *)
        ;;
esac

# # Execute the emacs daemon if it was not running
# if [ ! -e /tmp/emacs*  ]
# then
#     $E --daemon
# fi

#echo -e "\e[44m ** lauching asynchronous Emacs Client ** \e[00m"

EXEC="$EC $OPT $@"

echo ">>> $EXEC"
eval $EXEC

# I dont like the prompt being missing after
# an asynchronous call, so wait a bit for the output.
#sleep 0.5


