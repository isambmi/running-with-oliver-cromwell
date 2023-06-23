#!/bin/bash
wdl=/home/imibrahim/cromwell/seqconv-markadapt/seqConvMarkAdapt.wdl

while getopts i:g: flag
do
    case "${flag}" in
        i) inputdir=${OPTARG};;
        g) groupname=${OPTARG};;
    esac
done

ls ${inputdir}/*.json | xargs -I % oliver submit ${wdl} % -g ${groupname}