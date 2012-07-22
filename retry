#!/bin/bash

eval $@
while [ "$?" != "0" ]
do
    echo -e "\e[31m${0##*/}\e[0m: evaluation exit value $? - Retrying..."
    sleep 1
    eval $@
done
