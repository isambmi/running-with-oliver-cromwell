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

## Dependencies

This walkthrough assumes that user and/or their environment has the following:
1. Conda: A new environment is highly recommended
2. [Oliver](https://stjudecloud.github.io/oliver/): Installing via `pip` is highly recommended, regardless of conda environment.
3. Access to the Arashi server:
- wrapper scripts are located at `/home/cromwell-scripts/` 

## Overview

A brief introduction, including configuring Oliver is available 

## Available pipelines

1. RNA-seq mutation calling pipeline
   - Adapted from GATK's best practices
2. DNA-seq mutation calling pipeline
   - Implementation of GATK's best practices


