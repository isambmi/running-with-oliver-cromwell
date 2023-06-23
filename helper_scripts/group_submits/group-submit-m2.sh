#!/bin/bash
# script used to mass submit m2 workflows and assign all workflows a shared groupname for ease of post workflow aggregation of results or logs
# requires the following flags:
# -i & -g as follows

while getopts i:g: flag
do
    case "${flag}" in
        # location of input files containing lists of unaligned BAMs or in the wdl parlance flowcell_unmapped_bams_list. no need for trailing '/'
        i) inputdir=${OPTARG};; 
        # groupname to give the workflows
        g) groupname=${OPTARG};; 
    esac
done

# Arashi path
basecdir=/home/cromwell-scripts/m2

ls ${inputdir}/* | xargs -I % oliver submit ${basecdir}/mutect2.wdl % @/home/cromwell-scripts/default-options.json @hogGroup=${groupname} --grid-style pipe -g ${groupname} 
