#!/bin/sh

# Fernando Carmona Varo <ferkiwi@gmail.com>

#---
# Wrapper around gpg to encrypt/decrypt a file or directory
# it will also (de)compress them
#---

[ -e "$1" ] && [ -z "$2" ] || {
    echo "Usage: ${0##*/} <file or directory>"
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
    *.tar|*.tar.*|*.t?z)
	gpg -e "$1"
	;;
    *)
	out="${1%/}.txz.gpg"
	tar cJ "$1" | gpg -o "$out" -e -
	ls -lh "$out"
	;;
esac
