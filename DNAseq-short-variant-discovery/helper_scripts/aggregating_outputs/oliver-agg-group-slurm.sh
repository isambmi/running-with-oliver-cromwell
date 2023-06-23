#!/bin/bash
#SBATCH --job-name=aggregating
#SBATCH --partition=bioinfo
#SBATCH --account=bioinfo
#SBATCH --nodelist=node-0026
#SBATCH --nodes=1
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4GB
#SBATCH --error=/home/isambmi/logs/cromwellserver/aggregating-%A-%a.err
#SBATCH --output=/home/isambmi/logs/cromwellserver/aggregating-%A-%a.out
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=isambmi@hawaii.edu

module load lang/Anaconda3
source activate cromjobs

# get group name
# get output folder 
while getopts g:o: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        o) output_dir=${OPTARG};;
    esac
done

# get successful workflow-ids from group
# there's an inverse here
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -P 50 -I % oliver aggregate -v % $output_dir 