#!/bin/bash
#mass submits preM2RNA workflows
# requires the following flags:
# -i & -g & -w as follows

while getopts i:g:w: flag
do
    case "${flag}" in
        # dir housing inputBams to be processed
        i) inputdir=${OPTARG};; 
        # groupname to give the workflows
        g) groupname=${OPTARG};; 
        # wdl to use
        w) wdl=${OPTARG};; 
    esac
done

# basecdir=/home/isambmi/biocore_lts/isam/cromwell/preprocessing
basecdir=/home/isambmi/biocore_lts/isam/cromwell/preM2RNA
ext=".bam"

cd ${basecdir}

ls ${inputdir}/*${ext} | \
xargs -I % \
oliver submit ${wdl} defaultPlus.json preM2RNAseqPlus.inputBam=% --grid-style pipe -g ${groupname}