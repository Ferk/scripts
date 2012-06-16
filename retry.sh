#!/bin/bash

$@
while [ "$?" != "0" ]
do
    echo "err=\"$?\" - Retrying..."
    sleep 1
    $@
done
