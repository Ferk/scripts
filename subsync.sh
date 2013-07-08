#!/bin/bash


# Fernando Carmona Varo <ferkiwi@gmail.com>

#---
# Script for synchronization of SRT subtitle files
#---

showhelp() {
    prog="${0##*/}"
    cat <<EOF 
Usage: $prog [filename] [delay] [multiplier]
For delay only, set multiplier to 1.

Use: $prog alfa1 beta1 alfa2 beta2
to calculate [Delay]  & [Multiplier] for alfa1-->beta1 & alfa2-->beta2.
Time format= hour:minute:second.
EOF
}

do_sync() {
    local srtfile="$1"
    local newsrt="${srtfile}.synced"

    cat "$1"|sed 's/ --> /:/'|gawk -v delay=$2 -v multi=$3 '
BEGIN { FS=":" } 
NF<4 { print $0 } 
NF>4 { gsub(",",".");
stime=$1*3600+$2*60+$3;
etime=$4*3600+$5*60+$6;
nstime=stime*multi+delay;
netime=etime*multi+delay;
sh=int(nstime/3600);
eh=int(netime/3600);
sm=int((nstime-sh*3600)/60);
em=int((netime-sh*3600)/60);
ss=int(1000*(nstime-sh*3600-sm*60))/1000;
es=int(1000*(netime-eh*3600-em*60))/1000;
if (sh<10) sh="0"sh;
if (sm<10) sm="0"sm;
if (ss<10) ss="0"ss;
if (eh<10) eh="0"eh;
if (em<10) em="0"em;
if (es<10) es="0"es;
if (length(es)<6) es=es"0";
if (length(ss)<6) ss=ss"0";
$0=sh":"sm":"ss" --> "eh":"em":"es;gsub("\\.",",");
print
}' > "$newsrt" 

    mv -v --backup=numbered "$srtfile"  "${srtfile}.old"
    mv -v "$newsrt" "$srtfile"
}


if [ $# -eq 3 ]
then
    do_sync "$@" && exit 0
elif [ $# -eq 4 ]
then
    echo $@|sed 's/ /:/g'|gawk '
BEGIN {FS=":"} 
{a1=$1*3600+$2*60+$3;a2=$4*3600+$5*60+$6;a3=$7*3600+$8*60+$9;a4=$10*3600+$11*60+$12; multi=(a4-a2)/(a3-a1);delay=a4-a3*multi;print "Time Delay :",delay,"\nMultiplier :",multi;estim1=a1*multi+delay;estim2=a3*multi+delay}' && exit 0;

else
    showhelp
    exit 0
fi
