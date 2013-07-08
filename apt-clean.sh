#!/bin/sh

#---
# Script for APT package manager based systems, for cleaning it up of
# installed packages, and clearing cache files.
#---

if [ $(id -u) -ne 0 ]
then
    sudo -p "This tool must be run as root. Enter password:" "$0" "$@"
    exit $?
fi

PKGS=$(mktemp apt-clean-pkgs-XXXX.tmp)

printf "Loading packages...\nWriting to file '$PKGS'"

printf "# Uncomment the packages that you don't want (if they depend on soemthing else they won't be uninstalled)\n\n" > $PKGS

aptitude -F "%p" search \!~M~i~T | sed "s/^/#/" >> $PKGS


${EDITOR:-nano} $PKGS

echo "Marking chosed packages as automatic..."

aptitude markauto $(sed "/^#/d" $PKGS)

rm -v $PKGS

echo "Purging configuration files and cache..."

aptitude purge ~c -y

aptitude clean

rm -f /var/log/*.gz /var/log/*.1
