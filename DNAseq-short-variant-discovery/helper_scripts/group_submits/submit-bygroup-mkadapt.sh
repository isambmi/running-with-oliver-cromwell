#!/bin/bash
wdl=/home/imibrahim/cromwell/markadapters/markilluminaadapters.wdl
def_input=/home/imibrahim/cromwell/markadapters/markadapters.json

while getopts i:g: flag
do
    case "${flag}" in
        i) inputdir=${OPTARG};;
        g) groupname=${OPTARG};;
    esac
done

ls $inputdir/*.bam | grep -v BGI-EX01N.FCD21V6ACXX.1.unmapped.bam | xargs -I % -P 50 oliver submit ${wdl}  MarkAdapters.bam=% -g ${groupname} 