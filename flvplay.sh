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

mplayer -fs  $stream

# Save file
if [ $UID = "0" ]; then
  echo "You shouldn't run me as root!"
  exit 1
fi

echo "** SAVE AS... **"
echo "Type a name for the file (without extension) to be saved"
echo -n " or just press enter for no saving: "
read save
[ $save ] && { cp -i $stream "$save.flv" && ls -l "$save.flv" }

