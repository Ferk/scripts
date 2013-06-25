
#!/bin/bash

#---
# Not really very useful anymore, since emacs already improved
# emacsclient invocation, but this was my wrapper around emacs.
#---

OPTS='-c -a ""'

# choose the emacs snapshot version if present
if [ -e /usr/bin/emacs-snapshot ]
then
    EC="emacsclient.emacs-snapshot"
    E="emacs-snapshot "
else
    EC="emacsclient"
    E="emacs"
fi

# When executed in a supported terminal, don't use an X window
case "$TERM" in
    xterm*|rxvt*|*-256color)
        OPTS="$OPTS -nw"
        ;;
    *)
        ;;
esac

# # Execute the emacs daemon if it was not running
# if [ ! -e /tmp/emacs*  ]
# then
#     $E --daemon
# fi

EXEC="$EC $OPTS $@"

#echo "> $EXEC"
eval $EXEC
