#!/bin/bash
#mass submits preM2RNA workflows
# requires the following flags:
# -i & -g as follows

while getopts i:g: flag
do
    case "${flag}" in
        # dir housing inputBams to be processed
        i) inputdir=${OPTARG};; 
        # groupname to give the workflows
        g) groupname=${OPTARG};; 
    esac
done

# basecdir=/home/isambmi/biocore_lts/isam/cromwell/preprocessing
basecdir=/home/isambmi/biocore_lts/isam/cromwell/m2
ext=".bam"

cd ${basecdir}

# first part lists bams and filters to generate sample name to pass to xargs
ls $inputdir/*bam | rev | cut -d"/" -f1 | rev | cut -d"." -f1 | cut -d"_" -f1 | sort | uniq | \
xargs -I % \
oliver submit mutect2-RNA.wdl m2-rna-default.json \
Mutect2.sample_name=% \
Mutect2.tumor_reads=${inputdir}/%_C.aligned.duplicates_marked.recalibrated.bam \
Mutect2.tumor_reads_index=${inputdir}/%_C.aligned.duplicates_marked.recalibrated.bai \
Mutect2.normal_reads=${inputdir}/%_N.aligned.duplicates_marked.recalibrated.bam \
Mutect2.normal_reads_index=${inputdir}/%_N.aligned.duplicates_marked.recalibrated.bai \
--grid-style pipe -g ${groupname}