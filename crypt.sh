#!/bin/sh
#
# Wrapper around gpg to encrypt/decrypt files and directories
# it will also (de)compress them with tar.xz 
#
# Fernando Carmona Varo
#

[ -e "$1" ] || {
    echo "Usage: ${0##*/} <file>"
    exit
}

case "$1" in

# Decrypt (*.gpg files)
    *.txz.gpg|*.tar.xz.gpg)
	gpg -d "$1" | tar xJv
	;;
    *.tgz.gpg|*.tar.gz.gpg)
	gpg -d "$1" | tar xzv
	;;
    *.gpg)
	gpg -d "$1" -o "${1%.gpg}"
	;;

# Encrypt (any other file)
    *.tar*)
	gpg -e "$1"
	;;
    *)
	tar cJ "$1" | gpg -o "$1.txz.gpg" -e -
	ls -lh "$1.txz.gpg"
	;;
esac
