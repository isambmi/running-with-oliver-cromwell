# Running the DNA-seq short variant discovery pipeline

This pipeline is adapted  from [GATK's best practices for Somatic short variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-). The WDLs remain the same for the most part with some small changes made to account for the environment and local requirements. Most if not all of the steps use singularity containers, so there is no need to configure an environment for each tool/step.

This pipeline takes metadata of a group of samples and processes them together with the final product being a single annotated MAF file comprising of all the SNVs from each sample.

# Requirements

1. Same as the [general requirements](README.md#requirements)
    - as mentioned in the general requirements, the wrapper scripts (used for group submission and aggregation) can be found at `/home/cromwell-scripts`
    - the "working directories" mentioned in this guide refer to directories on the ARASHI server. The steps and commands of each section are expected to be run from their respective working directories.
2. Raw DNA sequencing files. These can be either aligned BAM, unaligned BAM or fastq files. The “seq-conversion.wdl” used may differ depending on this input.
3. Suitable inputs for each step of the pipeline. 
    - As is the case of any pipeline, the most important part is getting the input right. Also as in any good pipeline, the output from each step should feed the subsequent step. The obvious departure from this is the first step, for which a python script (and notebook) have been provided to help with creating the expected input.
    - WDL expects json, not the actual files, and examples of these will be included/referenced
4. A CSV file ([example](example_inputs/example_meta.csv)) containing sample metadata. Unless stated otherwise, the expected CSV file should contain the following columns:
    - `readgroup`: Read group name ([notes on defining RG, library_name, and platform_unit](https://gatk.broadinstitute.org/hc/en-us/articles/360035890671-Read-groups)), but can simply use `sample_name`
    - `sample_name`: Sample name
    - `subject_id`: unique ID of subject/patient
    - `sample_type`: either Tumor (T) or Normal (N)
    - `absolute_path_to_fq1`: absolute path to fastq1 on ARASHI
    - `absolute_path_to_fq2`: absolute path to fastq2 on ARASHI
    - `library_name`, can be same as sample name
    - `platform_unit` **(optional)**: platform unit
    - `sequence_date`: sequence date (e.g. format `2022-05-31T11:52:00`)
    - `sequence_platform`: sequence platform
    - `sequence_center`: sequence center

# Tips

- It is **highly recommended** to submit a "pilot" group to monitor the resource requirements for each stage of the pipeline. If necessary, split the a large into smaller subgroups. Failure to do so could result in the server being severely bogged down and inaccessible to other users. Don't be *that* guy.
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
    
    Hint: the `logs` command usually outputs directory of the stdout and stderr logs for a particular workflow. If command does not list out the log files but instead outputs a cryptic one-liner, it is likely an issue with the actual input file (wrong path/dir/etc). Try `ls` the path to the file in the `input.json` for a quick test.

# Generating pipeline input

Before running any of [the pipeline](#the-pipeline) scripts, first generate the required inputs for [SCMA](#a-sequence-format-conversion--marking-adapters-scma), [PoN](#c-generating-panel-of-normals-pon), and [M2](#d-variant-calling-with-mutect2-m2) using the [provided notebook](preparing_inputs/general_gatk_input_gen.ipynb).

**A note on "Capture Kit/Interval list", which are required to generate input for [PoN](#c-generating-panel-of-normals-pon) and [M2](#d-variant-calling-with-mutect2-m2)**

- Common kits are Agilent SureSelect. Converted bed files for these are available in `ref_dir`. Links to common kits:
    1. SureSelect Human All Exon V5
        - Downloading from [Agilent](https://earray.chem.agilent.com/suredesign) and as described [here](https://www.biostars.org/p/5187/):
            - “Find Designs” → “Agilent Catalog”
            - Most likely will be interested in `*[design_ID]_Regions.bed*`
        - BED file is at `/home/imibrahim/refs/Agilent_SureSelect_Human_All_Exon_V5`
- Files must be converted to use naming convention (e.g. chromosome 1 is `1` not `chr1`).
    - To convert run:
    
    ```bash
    sed -i 's/chr//g' S04380110_Regions.bed
    ```
    
    
# The Pipeline

## A. Sequence format conversion + marking adapters (SCMA)

**Working directory**: `/home/cromwell-scripts/seqconv-markadapt`

**WDL:** `seqConvMarkAdapt.wdl`

**Input(s)**: 

- [example_scma_input.json](example_inputs/example_scma_input.json)
    - note: update value of `send_email` and `email` to receive email on workflow completion

**Output(s)**: 

- unaligned BAM (uBAM) with adapter sequence marked
- `fofn.list`
    - a text file containing the path(s) to the generated uBAM(s).
    - used in lieu of an input.json in the next step ([Pre-Processing](#b-pre-processing-pp)).
    - Using a “file list” simplifies storage management.

---

1. Prepare input jsons with Section A of the [provided notebook](preparing_inputs/general_gatk_input_gen.ipynb).


2. Submit group of inputs to Cromwell with:

    ```bash
    ./group-submit-scma.sh -i /path/to/dir/with/input -g ${groupname}
    ```
    - it is recommended to submit tumor and normal fastqs as separate groups (`-N/T`) to simplify pointing to the tumor/normal files when generating input for [PoN](#c-generating-panel-of-normals-pon) and [M2](#d-variant-calling-with-mutect2-m2).

3.  Aggregate `fofn.list` with:

    ```bash
    ./group-agg-scma_lists.sh -g ${groupname} -o ${output_directory}
    ```

## B. Pre-processing (PP)

**Working directory**: `/home/cromwell-scripts/preprocessing`

**WDL:** `processing-for-variant-discovery.wdl`

**Input(s):** 
- `fofn.lists` from [SCMA](#a-sequence-format-conversion--marking-adapters-scma).

**Output(s):** 

- aligned BAM file (b37/hg38)
   
---

1. Submit groups of uBAMs for pre-processing with:

    ```bash
    ./group-submit-pp.sh -i /path/to/dir/containing/scma/lists -g ${groupname} -r ${b37/hg38}
    ```
    - note: the `-r` flag selects reference files located in `/home/isam/refs` and specific `default.json` files. If a different reference is required, please create a modified copy of the [`group-submit-pp.sh`](helper_scripts/group_submits/group-submit-pp.sh) script that points to an alternate `default-processing.json` and reference files.
    - Like in [SCMA](#a-sequence-format-conversion--marking-adapters-scma), it is recommended to submit tumor and normal fastqs as separate groups (`-N/T`) to simplify pointing to the tumor/normal files when generating input for [PoN](#c-generating-panel-of-normals-pon) and [M2](#d-variant-calling-with-mutect2-m2).

2. Aggregate results with script from base cromwell-scripts directory:

    ```bash
    ./agg-grp-output.sh -g ${groupname} -o ${output_directory}
    ```

## C. Generating Panel of Normals (PoN)

**Working directory**: `/home/cromwell-scripts/m2`

**WDL:** `mutect_pon.wdl`

**Input(s)**: 

- - [example_pon_input.json](example_inputs/example_pon_input.json)
    - note: update value of `send_email` and `email` to receive email on workflow completion

**Output(s)**: 

- PoN

---

1. Generate input.json using notebook
    1. Make sure paths to reference files are correct
    2. If WXS, identify Library Prep/Capture kit used. 
    3. Set appropriate `scatter_count`
2. Run with:

    ```bash
    ./submit-pon.sh -i ${/path/to/input.json} -g ${groupname}
    ```

1. Aggregate pon file with:

    ```bash
    ./agg-pon.sh -g ${groupname} -o ${/dir/to/output/pon}
    ```

## D. Variant calling with Mutect2 (M2)

**Working directory**: `/home/cromwell-scripts/m2`

**WDL:** `mutect2.wdl`

**Input(s)**: 

- [example_m2_input.json](example_inputs/example_m2_input.json)
    - note: update value of `send_email` and `email` to receive email on workflow completion

**Output(s)**: 

- Sample mutation calls in MAF format

---


> 
1. Generate input.json using notebook
    1. Add location of PoN file generated from section C
    2. Make sure paths to reference files are correct
    3. If WXS, identify Library Prep/Capture kit used (link to notes on obtaining kit).
    - Note: Mutation calling can be made stricter or more permissive by modifying `Mutect2.m2_extra_args` parameter in the notebook. 
2. Run variant calling with:

    ```bash
    ./group-submit-m2.sh -i ${/full/path/to/inputs/dir} -g ${groupname}
    ```

1. Aggregate results with `/home/cromwell-scripts/agg-grp-output.sh`:

    ```bash
    ./agg-grp-output.sh -g ${groupname} -o ${/full/path/to/output/dir}
    ```

## E. Aggregating MAFs

**Working directory**: `/home/cromwell-scripts`

**Input(s)**: 

- collection of individual MAFs from [variant calling](#d-variant-calling-with-mutect2)

**Output(s)**: 

- An `.aggregated.maf` file

---

1. Using editors like `vi` or `less` check the number of meta lines preceding the header in the MAF files generated from [variant calling](#d-variant-calling-with-mutect2). Each MAF from the same project run should have the same number of meta lines. The number of meta lines in a typical Funcotated MAF is 159, (160 is where the header starts), however, results can vary depending on the source material.
2. Using the number of meta lines in step 1, run:

```bash
./maf_concatenator.sh -m ${/path/to/mafs} -n ${number_of_meta_lines+1} -o ${/path/to/output/dir} -p ${project_name}
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
