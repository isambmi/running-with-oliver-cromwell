#!/bin/bash

# get group name
# get and status [Failed, Succeeded, Running]
while getopts g:s: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        s) status=${OPTARG};;
    esac
done

# get successful workflow-ids from group
oliver st -d -g ${groupname} --grid-style pipe | grep ${status} | cut -d"|" -f3 | sed 's/ *//g'