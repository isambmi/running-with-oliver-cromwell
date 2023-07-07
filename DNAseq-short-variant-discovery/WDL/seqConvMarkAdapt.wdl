version 1.0

##Copyright Broad Institute, 2018
## 
## This WDL is modified from Broad's original WDL which converts paired FASTQ to uBAM and adds read group information then marks adapter sequences (XT)
##
## Requirements/expectations :
## - Pair-end sequencing data in FASTQ format (one file per orientation)
## - The following metada descriptors per sample:
##  - readgroup
##  - sample_name
##  - library_name
##  - platform_unit
##  - run_date
##  - platform_name
##  - sequecing_center
##
## Outputs :
## - Set of unmapped BAMs, one per read group
## - File of a list of the generated unmapped BAMs
##
## Cromwell version support 
## - Successfully tested on v47
## - Does not work on versions < v23 due to output syntax
##
## Runtime parameters are optimized for Broad's Google Cloud Platform implementation. 
## For program versions, see docker containers. 
##
## LICENSING : 
## This script is released under the WDL source code license (BSD-3) (see LICENSE in 
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may 
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script. Please see the docker 
## page at https://hub.docker.com/r/broadinstitute/genomes-in-the-cloud/ for detailed
## licensing information pertaining to the included programs.

# WORKFLOW DEFINITION
workflow seqConvMarkAdapt {
  input {
    String sample_name 
    String fastq_1 
    String fastq_2 
    String readgroup_name 
    String library_name 
    String platform_unit 
    String run_date 
    String platform_name 
    String sequencing_center 

    Boolean make_fofn = false

    Boolean send_email = false
    String? email

    String gatk_docker = "arashi-gatk-42"
    String ubuntu_docker = "arashi-ubuntu"
    String gatk_path = "/gatk/gatk"
    
    # Sometimes the output is larger than the input, or a task can spill to disk.
    # In these cases we need to account for the input (1) and the output (1.5) or the input(1), the output(1), and spillage (.5).
    Float disk_multiplier = 2.5
  }

    String ubam_list_name = sample_name

  # Convert pair of FASTQs to uBAM
  call PairedFastQsToUnmappedBAM {
    input:
      sample_name = sample_name,
      fastq_1 = fastq_1,
      fastq_2 = fastq_2,
      readgroup_name = readgroup_name,
      library_name = library_name,
      platform_unit = platform_unit,
      run_date = run_date,
      platform_name = platform_name,
      sequencing_center = sequencing_center,
      gatk_path = gatk_path,
      docker = gatk_docker,
      disk_multiplier = disk_multiplier
  }

  # Mark adapter sequences in bams
  call MarkIlluminaAdapters {
    input:
      bam = PairedFastQsToUnmappedBAM.output_unmapped_bam,
      gatk_path = gatk_path,
      docker = gatk_docker,
  }
  
  #Create a file with the generated ubam
  if (make_fofn) {  
    call CreateFoFN {
      input:
        ubam = MarkIlluminaAdapters.output_marked_bam,
        fofn_name = ubam_list_name,
        docker = ubuntu_docker
    }
  }

  if (send_email) {
    call ScmaComplete {
      input:
        marked_bam = MarkIlluminaAdapters.output_marked_bam,
        email = email
    }
  }

  # Outputs that will be retained when execution is complete
  output {
    File? fofn_list = CreateFoFN.fofn_list
    File output_marked_bam = MarkIlluminaAdapters.output_marked_bam
    File? adapter_metrics_txt = MarkIlluminaAdapters.adapter_metrics_txt
  }
  
}

# TASK DEFINITIONS

# Convert a pair of FASTQs to uBAM
task PairedFastQsToUnmappedBAM {
  input {
    # Command parameters
    String sample_name
    File fastq_1
    File fastq_2
    String readgroup_name
    String library_name
    String platform_unit
    String run_date
    String platform_name
    String sequencing_center
    String gatk_path

    # Runtime parameters
    Int machine_mem_gb = 6
    Int preemptible_attempts = 3
    String docker
    Float disk_multiplier
  }
    Int command_mem_gb = machine_mem_gb - 1
  command {
    mkdir tmpdir

    ~{gatk_path} --java-options "-Xmx~{command_mem_gb}g" \
    FastqToSam \
    --TMP_DIR tmpdir \
    --FASTQ ~{fastq_1} \
    --FASTQ2 ~{fastq_2} \
    --OUTPUT ~{readgroup_name}.unmapped.bam \
    --READ_GROUP_NAME ~{readgroup_name} \
    --SAMPLE_NAME ~{sample_name} \
    --LIBRARY_NAME ~{library_name} \
    --PLATFORM_UNIT ~{platform_unit} \
    --RUN_DATE ~{run_date} \
    --PLATFORM ~{platform_name} \
    --SEQUENCING_CENTER ~{sequencing_center} 

    rm -rf tmpdir
  }
  runtime {
    docker: docker
  }
  output {
    File output_unmapped_bam = "~{readgroup_name}.unmapped.bam"
  }
}

# Mark adapter sequences in bams
task MarkIlluminaAdapters {
  input {
    # Command parameters
    File bam
    String bam_basename = basename(bam, ".bam")

    Int machine_mem_gb = 11
    Int preemptible_attempts = 3
    String docker
    String gatk_path
  }
    Int command_mem_gb = machine_mem_gb - 1
  runtime {
    docker: docker
    runtime_minutes: 180
    cpus: 4
    memory: "8 GB"
    preemptible: preemptible_attempts
  }
  command {
    mkdir tmpdir

    ~{gatk_path} --java-options "-Xmx~{command_mem_gb}g" \
    MarkIlluminaAdapters \
    --TMP_DIR tmpdir \
    -I ~{bam} \
    -O ~{bam_basename}.marked.bam \
    -M ~{bam_basename}_metrics.txt

    rm -rf tmpdir
    
  }
  output {
    File output_marked_bam = "~{bam_basename}.marked.bam"
    File adapter_metrics_txt = "~{bam_basename}_metrics.txt"
  }
}

# Creats a file of file names of the uBAM, which is a text file with each row having the path to the file.
# In this case there will only be one file path in the txt file but this format is used by 
# the pre-processing for variant discvoery workflow. 
task CreateFoFN {
  input {
    # Command parameters
    String ubam
    String fofn_name
    String docker
  }
  command {
    echo ~{ubam} > ~{fofn_name}.list
  }
  output {
    File fofn_list = "~{fofn_name}.list"
  }
  runtime {
    docker: docker
  }
}

task ScmaComplete {
  input {
    String marked_bam
    String? email
  }
  command {
    echo "~{marked_bam} converted and marked" | mail -s "SCMA complete" ~{email}
  }
  runtime {
  }
  output {
    File response = stdout()
  }
}
