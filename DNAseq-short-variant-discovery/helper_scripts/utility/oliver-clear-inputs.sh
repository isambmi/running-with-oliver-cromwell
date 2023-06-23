#!/bin/bash

# get group name
# get output folder 
while getopts g:w: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        w) workflow=${OPTARG};;
    esac
done



base_exec_dir="/home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/${workflow}"

# get successful workflow-ids from group and 
oliver status -g ${groupname} -d --grid-style pipe | tail -n +3 | cut -d'|' -f3 | awk '{$1=$1};1' | xargs -I % -P 40 find ${base_exec_dir}/% -type d -name inputs -prune -exec rm -rf {} \;