#!/bin/bash
# copies (aggregates) the outputs from each workflow in a group together in the specified output directory

# get group name
# get output folder 
while getopts g:o: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        o) output_dir=${OPTARG};;
    esac
done

mkdir -p ${output_dir}

# get successful workflow-ids from group
# and aggregate each successful result
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -P 50 -I % oliver aggregate -v % $output_dir 
# either above or below should work
# oliver status -g ${groupname} -d --grid-style NONE | grep Succeeded | awk -F '  ' '{print $2}' | xargs -P 50 -I % oliver aggregate -v % ${output_dir}