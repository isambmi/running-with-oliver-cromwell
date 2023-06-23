#!/bin/bash

#SBATCH --job-name=clearing_fqs
#SBATCH --partition=bioinfo
#SBATCH --account=bioinfo
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=19
#SBATCH --mem=100GB
#SBATCH --error=/home/isambmi/logs/util/clearingfq-%A-%a.err
#SBATCH --output=/home/isambmi/logs/util/clearingfq-%A-%a.out
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=isambmi@hawaii.edu

# get group name
# get output folder 
while getopts f:i: flag
do
    case "${flag}" in
        f) fqdir=${OPTARG};;
        i) inputfile=${OPTARG};;
    esac
done

# get successful workflow-ids from group and 
cat ${inputfile} | xargs -P 50 -I % find ${fqdir} -type f -name '%*' -prune -exec rm -rf {} \;