#!/bin/bash

$@
while [ "$?" != "0" ]
do
    echo "Retrying..."
    sleep 1
    $@
done
