#!/bin/bash
# script used to mass submit preprocessing workflows and assign all workflows a shared groupname for ease of post workflow aggregation of results or logs
# requires the following flags:
# -i & -g & -w as follows

while getopts i:g:w: flag
do
    case "${flag}" in
        # relative path from basecdir (defined below) to input files containing lists of unaligned BAMs or in the wdl parlance flowcell_unmapped_bams_list. no need for trailing '/'.
        i) inputdir=${OPTARG};; 
        # groupname to give the workflows
        g) groupname=${OPTARG};; 
        # specific wdl
        w) wdl=${OPTARG};; 
    esac
done

# basecdir=/home/isambmi/biocore_lts/isam/cromwell/preprocessing
basecdir=/home/imibrahim/cromwell/preprocessing

ls ${inputdir}/*.list | rev | cut -d"/" -f1 | cut -d"." -f2- | rev | xargs -I % oliver submit ${basecdir}/${wdl} ${basecdir}/default-processing.json PreProcessingForVariantDiscovery_GATK4.sample_name=% PreProcessingForVariantDiscovery_GATK4.flowcell_unmapped_bams_list=${inputdir}/%.list --grid-style pipe -g ${groupname}
