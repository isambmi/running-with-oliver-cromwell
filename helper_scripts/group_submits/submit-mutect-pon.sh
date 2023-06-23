## Mana paths
# wdl=/home/isambmi/biocore_lts/isam/cromwell/m2/mutect_pon.wdl
# dep=/home/isambmi/biocore_lts/isam/cromwell/m2/import.zip

#!/bin/bash
# Arashi paths
wdl=/home/cromwell-scripts/m2/mutect_pon.wdl
dep=/home/cromwell-scripts/m2/import.zip

while getopts i:g: flag
do
    case "${flag}" in
        i) inputjson=${OPTARG};;
        g) groupname=${OPTARG};;
    esac
done

oliver submit $wdl $inputjson --dependencies $dep -g $groupname