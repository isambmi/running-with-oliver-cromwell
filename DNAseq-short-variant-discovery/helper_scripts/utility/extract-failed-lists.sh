#!/bin/bash

# get group name
# get output folder 
while getopts g:o:n: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        o) originaldir=${OPTARG};;
        n) newdir=${OPTARG};;
    esac
done

# get successful workflow-ids from group

oliver st -g ${groupname} -d --grid-style pipe | grep -v Succeeded | grep ${groupname} | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % bash -c "
DIR2CHECK=\$(echo /home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/PreProcessingForVariantDiscovery_GATK4/%/call-SamToFastqAndBwaMem/shard-0/execution);
ls \$DIR2CHECK/*bam | rev | cut -d'/' -f1 | rev | cut -d'.' -f1 | xargs -I {} grep -r {} \${originaldir} | cut -d':' -f1 | grep -v ubam | sed 's/ *//g'"
# ls /home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/PreProcessingForVariantDiscovery_GATK4/%/call-SamToFastqAndBwaMem/shard-0/execution/*bam | rev | cut -d"/" -f1 | rev | cut -d"." -f1 
# | xargs -I {} grep -r {} ${originaldir} | cut -d":" -f1 | xargs -I ? mv ? ${newdir}