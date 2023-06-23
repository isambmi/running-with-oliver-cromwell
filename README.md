<!-- 
  <<< Author notes: Header of the course >>> 
  Include a 1280×640 image, course title in sentence case, and a concise description in emphasis.
  In your repository settings: enable template repository, add your 1280×640 social image, auto delete head branches.
  Add your open source license, GitHub uses Creative Commons Attribution 4.0 International.
-->

# Running WDL pipelines with Oliver+Cromwell

_A guide to submitting multiple workflows to a local Cromwell server concurrently with Oliver wrappers._

<!-- 
  <<< Author notes: Start of the course >>> 
  Include start button, a note about Actions minutes,
  and tell the learner why they should take the course.
  Each step should be wrapped in <details>/<summary>, with an `id` set.
  The start <details> should have `open` as well.
  Do not use quotes on the <details> tag attributes.
-->

<!--

1.  Dependencies
  - Create new conda environment
  - Install Oliver with pip
  
2. Next link to RNA variant calling pipeline
  

-->

This walkthrough is intended for use by the Deng Lab of Bioinformatics at the University of Hawaii Cancer Center, but should be applicable to any environment where a **local** implementation of [Cromwell](https://github.com/broadinstitute/cromwell) server has been deployed.

## Requirements

This walkthrough assumes that user and/or their environment has the following:
1. Conda: A new environment is highly recommended
2. [Oliver](https://stjudecloud.github.io/oliver/): Installing via `pip` is highly recommended, regardless of conda environment.
3. Access to the lab server:
   - wrapper scripts are located at `/home/cromwell-scripts/` 
   - cromwellserver address is `http://127.0.0.1:8089`

## Overview

An introduction to the basic idea and commands for using Oliver to handle and monitor workflow submissions is available on [Oliver's GitHub](https://stjudecloud.github.io/oliver/). This guide will not go into the specifics of how Oliver or Cromwell work, but instead focus on the execution of wrapper scripts that help submit multiple workflows to Cromwell via Oliver.

Instead this guide will only go over:
- Which script to use to execute a workflow (portion of a pipeline)
- What input the script expects/accepts

**WDL-Cromwell-Oliver diagram**

## Available pipelines

1. [RNA-seq mutation calling pipeline](RNAseq-short-variant-discovery.md)
   - Adapted from [GATK's best practices for RNAseq short variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035531192?id=3891)
2. [DNA-seq mutation calling pipeline](DNAseq-short-variant-discovery/README.md)
   - Implementation of GATK's best practices

## Wrapper scripts

The [wrapper scripts](DNAseq-short-variant-discovery/helper_scripts/) used throughout this guide are essentially wrappers around Oliver commands intended to simplify manipulations of workflow at the group level, which includes:

1. [Aggregating](DNAseq-short-variant-discovery/helper_scripts/aggregating_outputs/) (retrieving) the output of successful workflows by groupname
2. [Submitting](DNAseq-short-variant-discovery/helper_scripts/group_submits/) groups of workflows
3. [Other utility functions](DNAseq-short-variant-discovery/helper_scripts/utility/) such as concatenating MAFs into one aggregated grouped MAF file and clearing the output of previous workflows by workflow name.

