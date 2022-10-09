# Running the DNA-seq short variant discovery pipeline

This pipeline is adapted  from [GATK's best practices for Somatic short variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-). The WDLs remain the same for the most part with some small environment-specific adjustments made.

## Requirements

1. Same as the [general requirements](../README.md)
2. Raw DNA sequencing files. These can be either aligned BAM, unaligned BAM or fastq files. 

## Pre-processing

- Applies FixMateInformation and AddReadGroups to "prepare" BAM files
- location of scripts is `/home/cromwell-scripts/preM2RNA`
- run using:

```
group-submit-preM2RNA.sh
```

## Variant Calling

- Processes RNA-seq according to GATK best practices. 
- location of script is `/home/cromwell-scripts/m2-rna`
- run using:

```
group-submit-m2-RNA.sh
````
