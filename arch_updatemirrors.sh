#!/bin/sh

[ $UID != 0 ] && {
    sudo $0
    exit $?
}

TEMP=$(mktemp --suffix="-mirrorlist")

# Get the Official list of available mirrors
wget -O "$TEMP" http://www.archlinux.org/mirrorlist/all/

# Uncomment them all
sed '/^#\S/ s|#||' -i "$TEMP"

# Rank mirrors according to their response time and save 
# the 10 fastest ones in the default mirrorlist
rankmirrors -n 10 "$TEMP" > /etc/pacman.d/mirrorlist


