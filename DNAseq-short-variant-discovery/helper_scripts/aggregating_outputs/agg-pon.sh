#!/bin/bash

# get group name
# get output folder 
while getopts g:o: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        o) output_dir=${OPTARG};;
    esac
done

# get successful workflow-ids from group
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % oliver aggregate --dry-run % ${output_dir} | grep MergeVCFs | xargs -I {} bash -c {}