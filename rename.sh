#!/bin/sh

#---------
# Port of the perl 'rename' tool (also called prename) that is shipped in Debian, 
# this one only uses sh and sed for portability, so it also runs on cygwin.
# It will also preview the list of mv commands to perform and ask for verification
# before calling them.
#--------

MV='mv -vi'

sedexpr="$1"
shift

if [ -z "$1" ]
then
	cat <<EOF
Usage: ${0##*/} <sed expression> <filename ...>
EOF
	exit
fi

cmds=$({
	for file in "$@"
	do
		if ! [ -e "$file" ]
		then
			echo "file doesn't exit: $file" >&2
		else
			echo "$MV '${file/\'/\'\\\'\'}'"
			echo "#${file/\'/\'\\\'\'}"
		fi
	done
} | sed "/^#/{ s/^#//;${sedexpr};};" | sed "/$MV/{N;s/\n/ '/;s/$/'/}" | sed "/$MV '\([^']*\)' '\1'/d"
)

cat <<EOF
The following commands will be executed:

$cmds

EOF
echo -n "Are you sure you want to continue (Yn)? "
read y
[ "$y" != "n" ] && eval "$cmds"