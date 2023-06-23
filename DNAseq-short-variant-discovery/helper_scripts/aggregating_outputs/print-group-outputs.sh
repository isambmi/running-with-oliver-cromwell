#!/bin/bash

# get group name
# get output folder 
while getopts g: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
    esac
done

# get successful workflow-ids from group
# there's an inverse here
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % oliver outputs % --grid-style pipe