version 1.0
## Copyright Broad Institute, 2018
## 
## This WDL converts BAM  to unmapped BAMs
##
## Requirements/expectations :
## - BAM file
##
## Outputs :
## - Sorted Unmapped BAMs
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
workflow Bam2uMarkAdapt {
  input {
    File input_bam

    Int additional_disk_size = 20
    String gatk_docker = "arashi-gatk-42"
    String gatk_path = "/gatk/gatk"
    String ubuntu_docker = "arashi-ubuntu"
  }
    Float input_size = size(input_bam, "GB")
    String run_name = basename(input_bam, ".bam")
    
  call RevertSam {
    input:
      input_bam = input_bam,
      disk_size = ceil(input_size * 3) + additional_disk_size,
      docker = gatk_docker,
      gatk_path = gatk_path
  }

  scatter (unmapped_bam in RevertSam.unmapped_bams) {
    # original naming convention seems off now
    # String output_basename = basename(unmapped_bam, ".coord.sorted.unmapped.bam")
    String output_basename = basename(unmapped_bam, ".bam")
    Float unmapped_bam_size = size(unmapped_bam, "GB")

    call SortSam {
      input:
        input_bam = unmapped_bam,
        sorted_bam_name = output_basename + ".unmapped.bam",
        disk_size = ceil(unmapped_bam_size * 6) + additional_disk_size,
        docker = gatk_docker,
        gatk_path = gatk_path
    }
  
    # Mark adapter sequences in bams
    call MarkIlluminaAdapters {
      input:
        bam = SortSam.sorted_bam,
        gatk_path = gatk_path,
        docker = gatk_docker,
    }
  }

  call CreateFoFN {
    input:
      ubam = MarkIlluminaAdapters.output_marked_bam,
      docker = ubuntu_docker,
      fofn_name = run_name
  }

  output {
    File fofn_list = CreateFoFN.fofn_list
    Array[File] output_marked_bam = MarkIlluminaAdapters.output_marked_bam
  }
}

task RevertSam {
  input {
    #Command parameters
    File input_bam
    String gatk_path

    #Runtime parameters
    Int disk_size
    String docker
    Int machine_mem_gb = 2
    Int preemptible_attempts = 3
  }
    Int command_mem_gb = machine_mem_gb - 1    ####Needs to occur after machine_mem_gb is set 

  command { 
    mkdir tmpdir

    ~{gatk_path} --java-options "-Xmx~{command_mem_gb}g" \
    RevertSam \
    --TMP_DIR tmpdir \
    --INPUT ~{input_bam} \
    --OUTPUT ./ \
    --OUTPUT_BY_READGROUP true \
    --VALIDATION_STRINGENCY LENIENT \
    --ATTRIBUTE_TO_CLEAR FT \
    --ATTRIBUTE_TO_CLEAR CO \
    --SORT_ORDER coordinate

    rm -rf tmpdir
  }
  runtime {
    docker: docker
    disks: "local-disk " + disk_size + " HDD"
    memory: machine_mem_gb + " GB"
    preemptible: preemptible_attempts
  }
  output {
    Array[File] unmapped_bams = glob("*.bam")
  }
}

task SortSam {
  input {
    #Command parameters
    File input_bam
    String sorted_bam_name
    #Runtime parameters
    String gatk_path
    Int disk_size
    String docker
    Int machine_mem_gb = 4
    Int preemptible_attempts = 3
  }
    Int command_mem_gb = machine_mem_gb - 1    ####Needs to occur after machine_mem_gb is set 

  command {
    mkdir tmpdir
    
    ~{gatk_path} --java-options "-Xmx~{command_mem_gb}g" \
    SortSam \
    --TMP_DIR tmpdir \
    --INPUT ~{input_bam} \
    --OUTPUT ~{sorted_bam_name} \
    --SORT_ORDER queryname \
    --MAX_RECORDS_IN_RAM 1000000

    rm -rf tmpdir
  }
  runtime {
    docker: docker
    disks: "local-disk " + disk_size + " HDD"
    memory: machine_mem_gb + " GB"
    preemptible: preemptible_attempts
  }
  output {
    File sorted_bam = "~{sorted_bam_name}"
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
    Array[String] ubam
    # String ubam
    String fofn_name
    String docker
  }
  command {
    echo ~{sep="\n" ubam} > ~{fofn_name}.list
  }
  output {
    File fofn_list = "~{fofn_name}.list"
  }
  runtime {
    docker: docker
  }
}

