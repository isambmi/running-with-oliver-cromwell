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

mkdir -p ${output_dir}

# get successful workflow-ids from group and output to list
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' > tmp_succ_list

# loop through successful list
while read -r line;
do
    # find and cat FoFN list into a master FoFN (with the same name)
    fofn=`oliver outputs ${line} --grid-style pipe | grep fofn_list | cut -f3 -d'|' | sed 's/ *//g'`
    list_name=`echo $fofn | rev | cut -d"/" -f1 | rev`
    touch ${output_dir}/${list_name}
    cat $fofn >> ${output_dir}/${list_name}
done < tmp_succ_list
rm tmp_succ_list