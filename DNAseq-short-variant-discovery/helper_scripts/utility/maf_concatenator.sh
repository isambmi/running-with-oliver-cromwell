#!/bin/bash

# get project name
# get maf dir 
# get number of lines to skip
while getopts m:n:o:p: flag
do
    case "${flag}" in
        m) maf_dir=${OPTARG};;
        n) lines_to_skip=${OPTARG};;
        o) output_dir=${OPTARG};;
        p) project_name=${OPTARG};;
    esac
done

mkdir -p ${output_dir}

# Funcotated MAFs usually have 160 lines to skip
# aggregates all mafs together into a temp file
find ${maf_dir} -type f -name "*maf" | xargs -I % tail -n+${lines_to_skip} % >> ${output_dir}/${project_name}.aggregated.maf.tmp
# removes all but the first header
sed '1!{/^Hugo/d;};' ${output_dir}/${project_name}.aggregated.maf.tmp > ${output_dir}/${project_name}.aggregated.maf
# remove temp file
rm ${output_dir}/${project_name}.aggregated.maf.tmp
gzip ${output_dir}/${project_name}.aggregated.maf