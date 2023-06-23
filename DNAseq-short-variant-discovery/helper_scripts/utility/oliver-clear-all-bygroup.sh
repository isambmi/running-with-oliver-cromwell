#!/bin/bash

#SBATCH --job-name=clearing_cromwell
#SBATCH --partition=bioinfo
#SBATCH --account=bioinfo
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=19
#SBATCH --mem=100GB
#SBATCH --error=/home/isambmi/logs/cromwellserver/clearing-%A-%a.err
#SBATCH --output=/home/isambmi/logs/cromwellserver/clearing-%A-%a.out
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=isambmi@hawaii.edu

module load lang/Anaconda3
source activate cromjobs

# get group name
# get output folder 
while getopts g:w: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        w) workflow=${OPTARG};;
    esac
done



base_exec_dir="/home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/${workflow}"

# get successful workflow-ids from group and 
oliver status -g ${groupname} -d --grid-style pipe | tail -n +3 | cut -d'|' -f3 | awk '{$1=$1};1' | xargs -I % -P 40 find ${base_exec_dir}/% -type f -not \( -name stderr\* -o -name stdout\* -o -name script\* \) | xargs -I % -P 30 rm -rf %