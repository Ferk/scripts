#!/bin/sh
#
# Script to download the full list of arch mirrors,
# test them and select the fastest ones.
#
# Fernando Carmona Varo <ferkiwi@gmail.com>
#

[ "$(id -ru)" != 0 ] && {
    sudo -l $0 >&- && sudo $0
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


