#!/bin/bash

#SBATCH --job-name=clear_cromwell_inputs_wf
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
# get group name
# get output folder 
while getopts w: flag
do
    case "${flag}" in
        w) workflow=${OPTARG};;
    esac
done



base_exec_dir="/home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/${workflow}"

# get successful workflow-ids from group and 
find ${base_exec_dir}/ -type d -name inputs -prune -exec rm -rf {} \;