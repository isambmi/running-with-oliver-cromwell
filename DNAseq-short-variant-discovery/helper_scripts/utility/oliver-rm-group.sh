#!/bin/bash

# get group name
# get output folder 
while getopts g: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        # w) workflow=${OPTARG};;
    esac
done


# get all workflow-ids from group
workflow_name=`oliver st -g ${groupname} -d --grid-style pipe | grep ${groupname} | cut -d"|" -f4 | tr -d '[:blank:]' | head -n1`

oliver st -g ${groupname} -d --grid-style pipe | grep ${groupname} | grep ${workflow_name} | cut -d"|" -f3 | tr -d '[:blank:]' > tmp_succ_list_4rm_${groupname}


base_exec_dir="/home/cromwell-executions/${workflow_name}"

# loop through list of wfids from that group and...
while read -r wfid;
do
    # find and rm all non log files in wfid subdir
    find ${base_exec_dir}/${wfid} -type f -not \( -name stderr\* -o -name stdout\* -o -name script\* \) | xargs -I % -P 60 rm -rf -v %

done < tmp_succ_list_4rm_${groupname}

rm tmp_succ_list_4rm_${groupname}