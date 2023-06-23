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

mv 

# get successful workflow-ids from group
mkdir -p ${output_path}
oliver st -g ${groupname} -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % oliver aggregate --dry-run % ${output_path} | grep list | xargs -I {} bash -c {}

# successful groups are
CRC-NH-m2
CRC-NH-m2-5


oliver st -g CRC-NH-m2 -d --grid-style pipe | grep Succeeded | cut -d"|" -f3 | sed 's/ *//g' | xargs -I % -P 8 bash -c 'mv /home/isambmi/biocore_lts/isam/cromwell/cromwell-executions/Mutect2/%/call-Filter/execution/*vcf* .'