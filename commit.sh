#!/bin/sh
# 
# Commit script for SVN.
# Automatically adds/removes new/missing files (use svn:ignore for files you
# don't want to include).
#
# Commits also changes done to the repositories designed as externals.
#
# Reuses svn-commit.tmp files left from uncommitted messages.
#


externals=$(svn propget svn:externals | sed 's/.* //')

echo "Adding unversioned files"
echo "Note: to skip unwanted files add them to: svn propedit svn:ignore ."
svn add $(svn st | sed -n 's/^? *\(.*\)/\1/p') 2>/dev/null || true

echo "Delete missing files"
svn rm $(svn st | sed -n 's/^! *\(.*\)/\1/p') 2>/dev/null || true

svn st -u | grep "*" && {
    echo "Changes in the remote repository found! Updating before doing the commit."
    svn update
}

do_commit() {

    ( cd $1
	# Reuse tmp commit message from last failed commit
	if [ -f "svn-commit.tmp" ]
	then
	    echo "---- Recommiting on: $(date)" >> svn-commit.tmp
	    svn status >> svn-commit.tmp
	    ${EDITOR:-nano} svn-commit.tmp
	    ARGS="$ARGS -F svn-commit.tmp"
	    message=$(cat svn-commit.tmp | awk '/--.*--$/ {exit}; {print}')
	    if [ -z "$message" ]
	    then
		echo "Empty message, abort commit? (Yn)"
		read yn -sn 1
		[ "$yn" != "n" ] && return
	    fi
	fi
	echo "Committing"
	svn commit $ARGS
	if [ "$?" -eq 0 ]
	then
	    rm -fv svn-commit*.tmp
	fi
    )
}


for repo in . $externals
do
    do_commit $repo
done
