# wdl=/home/isambmi/biocore_lts/isam/cromwell/seqconv-markadapt/seqconv-markadapt.wdl
#!/bin/bash
wdl_dir=/home/imibrahim/cromwell/seq-conversion

while getopts i:g:w: flag
do
    case "${flag}" in
        i) inputdir=${OPTARG};;
        g) groupname=${OPTARG};;
        w) wdl=${OPTARG};;
    esac
done

ls ${inputdir}/*.json | xargs -I % oliver submit ${wdl_dir}/${wdl} % -g ${groupname}