# Running the RNA-seq short variant discovery pipeline

This pipeline is adapted from Adapted from [GATK's best practices for RNAseq short variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035531192?id=3891), with the most notable change being the additional pre-processing before performing variant calling.

## Requirements

1. Same as the [general requirements](README.md)
2. Algined RNA-seq files:
   - Alignment of RNA-seq is not covered by this pipeline. The primary input for this pipeline will be aligned RNA-seq in BAM format.

