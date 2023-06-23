
## this is still not the default at MANA

#!/bin/bash
# script used to mass submit preprocessing workflows and assign all workflows a shared groupname for ease of post workflow aggregation of results or logs
# requires the following flags:
# -i & -g & -w as follows

while getopts i:g:r: flag
do
    case "${flag}" in
        # relative path from basecdir (defined below) to input files containing lists of unaligned BAMs or in the wdl parlance flowcell_unmapped_bams_list. no need for trailing '/'.
        i) inputdir=${OPTARG};; 
        # groupname to give the workflows
        g) groupname=${OPTARG};; 
        # specific wdl
        # w) wdl=${OPTARG};; 
        # reference version
        r) ref=${OPTARG};;
    esac
done

wdl=processing-for-variant-discovery.wdl

basecdir=/home/cromwell-scripts/preprocessing
if [ $ref = 'b37' ]
then
    def_json=default-preprocessing.b37.json
else
    def_json=default-preprocessing.hg38.json
fi

default_json=${basecdir}/${def_json} 
echo "Submitting with default json ${default_json}"

ls ${inputdir}/*.list | rev | cut -d"/" -f1 | cut -d"." -f2- | rev | xargs -I % oliver submit ${basecdir}/${wdl} ${default_json} PreProcessingForVariantDiscovery_GATK4.sample_name=% PreProcessingForVariantDiscovery_GATK4.flowcell_unmapped_bams_list=${inputdir}/%.list --grid-style pipe -g ${groupname}
