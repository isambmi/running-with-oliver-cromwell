#!/bin/bash

#SBATCH --job-name=clearing_cromwell
#SBATCH --partition=bioinfo
#SBATCH --account=bioinfo
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=1GB
#SBATCH --error=/home/isambmi/logs/cromwellserver/clearing-%A-%a.err
#SBATCH --output=/home/isambmi/logs/cromwellserver/clearing-%A-%a.out
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=isambmi@hawaii.edu

# Clears all files in subdirs except std[err|out] and script
module load lang/Anaconda3
source activate cromjobs

# get workflow dir to be cleared
while getopts w: flag
do
    case "${flag}" in
        w) workflow=${OPTARG};;
    esac
done



base_exec_dir="/home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/${workflow}"

echo "Clearing ${workflow} output"

# get successful workflow-ids from group and 
find ${base_exec_dir} -type f -not \( -name stderr\* -o -name stdout\* -o -name script\* \) | xargs -I % -P 30 rm -rf %