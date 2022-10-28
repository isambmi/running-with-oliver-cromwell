# Running the DNA-seq short variant discovery pipeline

This pipeline is adapted  from [GATK's best practices for Somatic short variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-). The WDLs remain the same for the most part with some small changes made to account for the environment and local requirements.

# Requirements

1. Same as the general requirements
2. Raw DNA sequencing files. These can be either aligned BAM, unaligned BAM or fastq files. The “seq-conversion.wdl” used may differ depending on this input.
3. Suitable inputs for each step of the pipeline. 
    - As is the case of any pipeline, the most important part is getting the input right. Also as in any good pipeline, the output from each step should feed the subsequent step. The obvious departure from this is the first step, for which a python script (and notebook) have been provided to help with creating the expected input.
    - WDL expects json, not the actual files, and examples of these will be included/referenced.
    - [link to input generating notebook here]

# Tips

- Try and make the group names as unique as possible, group names are used a lot in this flow and separating each run properly can help prevent confusion/post-processing work.
- Check status of groups with
    
    ```bash
    oliver st -g ${groupname}
    ```
    
- Debug problems with `-d` flag to get ID list of workflows
    - use workflow ID in
    
    ```bash
    oliver inspect ${WFID}
    ```
    
    or 
    
    ```bash
    oliver logs ${WFID}
    ```
    
    Hint: the `logs` command usually outputs directory of the stdout and stderr logs for a particular workflow. If the output is a cryptic one-liner like in the output below,  it is most likely an issue with the actual input file (wrong path/dir/etc). Try `ls` the path to the file in the `input.json` for a quick test.
    

# A. Sequence format conversion + marking adapters (SCMA)

Base directory: `/home/cromwell-scripts/seq-conversion`

Input: input.json

Output: 

1. unaligned BAM (uBAM)
2. fofn list (used in subsequent step)

1. Prepare json input
2. Submit group of inputs with

```bash
$ ./submit-bygroup-seqconv.sh -i /home/cromwell-scripts/seq-conversion/input/JGAD110 -g JGAD110-scma-2 -w Bam2uMarkAdapt.wdl
```

1.  Aggregate scma lists results with:

```bash
$ ./group-agg-scma_lists.sh -g ${groupname} -o ${output_directory}
```

# B. Pre-processing (PP)

Base directory: `/home/cromwell-scripts/processing-for-variant-discovery`

Input: fofn lists from SCMA.

Output: 

1. aligned BAM

1. Submit groups of uBAMs for pre-processing with:

```bash
$ ./group-submit-pp.sh -i ${fofn_list_parent_dir} -g ${groupname} -w ${wdl}
```

# C. Generating Panel of Normals (PoN)

**Base directory**: `/home/cromwell-scripts/m2`

**WDL:** `mutect_pon.wdl`

**Input(s)**: 

- input.json
    - example json: `/private/var/lib/ddump/cromwell/crc-nh/HUMxlydR/pon.json`

**Output(s)**: 

- PoN

---

1. Generate input.json using notebook
    1. Make sure paths to reference files are correct
    2. If WXS, identify Library Prep/Capture kit used. 
    3. Set appropriate `scatter_count`
2. Run with:

```bash
$ ./submit-pon.sh -i ${/path/to/input.json} -g ${groupname}
```

1. Aggregate pon with:

```bash
$ ./agg-pon.sh -g ${groupname} -o ${/dir/to/output/pon}
```

# D. Variant calling with Mutect2

**Base directory**: `/home/cromwell-scripts/m2`

**WDL:** `mutect2.wdl`

**Input(s)**: 

- input.json
    - example json: `/private/var/lib/ddump/cromwell/crc-nh/HUMxlydR/m2/DCR0003.json`

**Output(s)**: 

- individual mutation call in MAF format

---

1. Generate input.json using notebook
    1. Add location of PoN file generated from section C
    2. Make sure paths to reference files are correct
    3. If WXS, identify Library Prep/Capture kit used (link to notes on obtaining kit). 
2. Run variant calling with:

```bash
$ ./group-submit-m2.sh -i ${/full/path/to/inputs/dir} -g ${groupname}
```

1. Aggregate results with `/home/cromwell-scripts/agg-grp-output.sh`:

```bash
$ ./agg-grp-output.sh -g ${groupname} -o ${/full/path/to/output/dir}
```

# E. Aggregating MAFs

**Base directory**: `/home/cromwell-scripts`

**Input(s)**: 

- individual MAFs from section D

**Output(s)**: 

- deduped.aggregated.maf

---

1. Using editors like `vi` or `less` check the number of meta lines preceding the header in the MAF files generated in section D. Each MAF from the same should have the same number of meta lines. The number of lines in a typical Funcotated MAF is 160, however, results can vary depending on the source material
2. Using the number of meta lines in step 1, run:

```bash
$ ./maf_concatenator.sh -m ${/path/to/mafs} -n ${number_of_meta_lines} -o ${/path/to/output/dir} -p ${project_name}
```

# Capture Kit/Interval list

1. Common kits are Agilent SureSelect. Converted bed files for these are available in `ref_dir`.  Files must be converted to use naming convention (e.g. chromosome 1 is `1` not `chr1`).
2. Link to agilent etc
    1. SureSelect Human All Exon V5
        - Downloading from [Agilent](https://earray.chem.agilent.com/suredesign) and as described [here](https://www.biostars.org/p/5187/):
            - “Find Designs” → “Agilent Catalog”
            - Most likely will be interested in `*[design_ID]_Regions.bed*`
        - BED file is at `/home/imibrahim/refs/Agilent_SureSelect_Human_All_Exon_V5`
3. To convert run:
    
    ```bash
    $ sed -i 's/chr//g' S04380110_Regions.bed
    ```
    

Before loading to db, check how unique the subject names are. Naming conventions like “Patient 1” would necessitate some
