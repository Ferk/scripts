#!/bin/sh
#
# Plays and offers to save the most recent flash video that is currently loaded
# 
# Fernando Carmona Varo
# Thanks to {r a y AT truedays . org}
#

stream=$(lsof / | grep Flash | awk '{
sub("[a-z]+","",$4);
print "/proc/"$2"/fd/"$4;
}' | tail -n 1)

[ -z $stream ] && { echo "No active Flash streams were found"; exit 1; }

mplayer -fs  $stream $@
sleep 1

echo "** SAVE AS... **"
echo "Type a filename (without extension) to save in $(pwd)"
printf " or just press enter for no saving: "
read save
[ $save ] && { cp -i $stream "$save.flv" && ls -l "$save.flv"; }
