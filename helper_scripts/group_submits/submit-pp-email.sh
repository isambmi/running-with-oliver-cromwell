#!/bin/bash

basecdir=/home/isambmi/biocore_lts/isam/cromwell/preprocessing
wdl=preprocessing-4vd-ks-wemail.wdl

while getopts i:g: flag
do
    case "${flag}" in
        i) inputlist=${OPTARG};;
        g) groupname=${OPTARG};;
    esac
done

ls ${inputlist} | rev | cut -d"/" -f1 | cut -d"." -f2- | rev | xargs -I % oliver submit ${basecdir}/${wdl} ${basecdir}/default-processing.json PreProcessingForVariantDiscovery_GATK4.sample_name=% PreProcessingForVariantDiscovery_GATK4.flowcell_unmapped_bams_list=${inputlist} PreProcessingForVariantDiscovery_GATK4.send_email=true --grid-style pipe -g ${groupname}