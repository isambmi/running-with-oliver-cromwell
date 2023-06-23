#!/bin/bash
# script to submit SRA download and fq workflows together as a group,
# requires the following inputs

while getopts i:g: flag
do
    case "${flag}" in
        # the inputlist to read from
        i) inputlist=${OPTARG};; 
        # groupname, for aggregating purposes
        g) groupname=${OPTARG};; 
    esac
done

wdl=/home/isambmi/biocore_lts/isam/cromwell/SraProcess/SraProcess.wdl

cat ${inputlist} | xargs -I % oliver submit ${wdl} default.json SraProcess.sra_run=% --grid-style pipe -g ${groupname}