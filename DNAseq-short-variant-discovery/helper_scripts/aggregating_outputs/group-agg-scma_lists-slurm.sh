#!/bin/bash
#!/bin/bash
#SBATCH --job-name=aggregating-scma
#SBATCH --partition=bioinfo
#SBATCH --account=bioinfo
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4GB
#SBATCH --error=/home/isambmi/logs/cromwellserver/aggregating-%A-%a.err
#SBATCH --output=/home/isambmi/logs/cromwellserver/aggregating-%A-%a.out
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=isambmi@hawaii.edu

module load lang/Anaconda3
source activate cromjobs

# pulls file of file names (fofn) that are usually outputted as a result of the seq-conversion and mark adapter workflows
# fofns are used as input for the pre-processing (pp) pipeline

# get group name
# get output folder 
while getopts g:o: flag
do
    case "${flag}" in
        g) groupname=${OPTARG};;
        o) output_dir=${OPTARG};;
    esac
done

# constructing output_path based on the output_dir (which is usually the group/project name i.e. phs488 to separate from inputs of other groups in the same dir)
output_path=/home/imibrahim/cromwell/preprocessing/input/${output_dir}

# get successful workflow-ids from group
mkdir -p ${output_path}
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % oliver aggregate --dry-run % ${output_path} | grep list | xargs -I {} bash -c {}