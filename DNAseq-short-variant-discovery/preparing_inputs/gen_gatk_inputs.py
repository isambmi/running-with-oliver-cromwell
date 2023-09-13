import pandas as pd
import json
import os
from configparser import ConfigParser
import sys
import argparse

def nl():
    print('\n')

def load_config(conf_ini="config.ini"):
    # Read config.ini file
    print("Reading keys in config.ini ...")
    conf = ConfigParser()
    conf.read(conf_ini)
    conf_keys = {}

    conf_keys['groupname'] = conf['RUNTIME']['groupname']
    conf_keys['input_file'] = conf['RUNTIME']['input_file']
    conf_keys['ref_version'] = conf['RUNTIME']['ref_version']
    conf_keys['raw_file_dir'] = conf['RUNTIME']['raw_file_dir'].rstrip('/').rstrip('\\')
    conf_keys['send_email_for_all'] = conf['RUNTIME']['send_email_for_all']

    conf_keys['interval_file'] = conf['RUNTIME']['interval_file']

    conf_keys['email'] = conf['USERCONFIG']['email']
    conf_keys['base_output_dir'] = conf['USERCONFIG']['base_output_dir'].rstrip('/').rstrip('\\')
    conf_keys['base_output_dir'] += "/" + conf_keys['groupname']

    conf_keys['n_dir'] = conf_keys['raw_file_dir'] + "/" + conf['RAWFILEDIRS']['n_dir'].rstrip('/').rstrip('\\')
    conf_keys['t_dir'] = conf_keys['raw_file_dir'] + "/" + conf['RAWFILEDIRS']['t_dir'].rstrip('/').rstrip('\\')
    conf_keys['pon_dir'] = conf_keys['raw_file_dir'] + "/" + conf['RAWFILEDIRS']['pon_dir'].rstrip('/').rstrip('\\')

    conf_keys['ref_dir'] = conf['SERVERCONFIG']['ref_dir'].rstrip('/').rstrip('\\')
    conf_keys['gatk_docker'] = conf['SERVERCONFIG']['gatk_docker']

    os.makedirs(conf_keys['base_output_dir'], exist_ok=True)
    print(f"Generated JSONs will be saved to: {conf_keys['base_output_dir']}")
    nl()
    return conf_keys

def load_inputcsv(input_file):
    # read input csv
    print(f"Loading input file: {input_file}")
    input_df = pd.read_csv(input_file)

    # check for required columns
    required_cols = ['readgroup', 'sample_name', 'subject_id', 'sample_type', 'absolute_path_to_fq1', 'absolute_path_to_fq2', 'library_name', 'platform_unit', 'sequence_date', 'sequence_platform', 'sequence_center']

    if not set(required_cols).issubset(input_df.columns):
        missing_cols = list(set(required_cols) - set(input_df.columns))
        print(f"Missing columns: {missing_cols}")
        sys.exit()
    nl()
    return input_df

def def_refs(conf_keys):
    ref_version = conf_keys['ref_version']
    interval_file = conf_keys['interval_file']
    ref_dir = conf_keys['ref_dir']
    base_output_dir = conf_keys['base_output_dir']
    groupname = conf_keys['groupname']

    ref_refs = {}

    # switching of references depending on ref_version
    if ref_version == "b37":
        if interval_file:
            ref_refs['interval_loc']=interval_file 
        else:
            ref_refs['interval_loc'] = f"{ref_dir}/Agilent_SureSelect_Human_All_Exon_V4/S03723314_Regions.converted.bed"
            print(f"`interval_file` not defined in config.ini. The following default interval file will be used instead: {ref_refs['interval_loc']}")

        ref_refs['ref_fasta'] = f"{ref_dir}/b37/human_g1k_v37_decoy.fasta"
        ref_refs['ref_fai'] = f"{ref_dir}/b37/human_g1k_v37_decoy.fasta.fai"
        ref_refs['ref_dict'] = f"{ref_dir}/b37/human_g1k_v37_decoy.dict"
        

        ref_refs['pon'] = f"{base_output_dir}/pon/{groupname}_pon.vcf"
        ref_refs['pon_idx'] = f"{base_output_dir}/pon/{groupname}_pon.vcf.idx"

        ref_refs['gnomad'] = f"{ref_dir}/b37/af-only-gnomad.raw.sites.vcf"
        ref_refs['gnomad_idx'] = f"{ref_dir}/b37/af-only-gnomad.raw.sites.vcf.idx"
        ref_refs['variants_for_contamination'] = f"{ref_dir}/b37/small_exac_common_3.vcf"
        ref_refs['variants_for_contamination_idx'] = f"{ref_dir}/b37/small_exac_common_3.vcf.idx"
        ref_refs['funco_data_source'] = f"{ref_dir}/b37/funcotator_dataSources.v1.7.20200521s.tar.gz"
    elif ref_version == "hg38":
        # only WGS version of interval list on disk for hg38
        if interval_file:
            ref_refs['interval_loc'] = interval_file 
        else:
            ref_refs['interval_loc'] = f"{ref_dir}/hg38/wgs_calling_regions.hg38.interval_list"
            print(f"`interval_file` not defined in config.ini. The following default interval file will be used instead: {ref_refs['interval_loc']}")

        ref_refs['ref_fasta'] = f"{ref_dir}/hg38/Homo_sapiens_assembly38.fasta"
        ref_refs['ref_fai'] = f"{ref_dir}/hg38/Homo_sapiens_assembly38.fasta.fai"
        ref_refs['ref_dict'] = f"{ref_dir}/hg38/Homo_sapiens_assembly38.dict"

        ref_refs['pon'] = f"{{base_output_dir}}/pon/1000g_pon.hg38.vcf.gz"
        ref_refs['pon_idx'] = f"{{base_output_dir}}/pon/1000g_pon.hg38.vcf.gz.tbi"

        ref_refs['gnomad'] = f"{ref_dir}/hg38/af-only-gnomad.hg38.vcf.gz"
        ref_refs['gnomad_idx'] = f"{ref_dir}/hg38/af-only-gnomad.hg38.vcf.gz.tbi"
        ref_refs['variants_for_contamination'] = f"{ref_dir}/hg38/small_exac_common_3.hg38.vcf.gz"
        ref_refs['variants_for_contamination_idx'] = f"{ref_dir}/hg38/small_exac_common_3.hg38.vcf.gz.tbi"
        ref_refs['funco_data_source'] = f"{ref_dir}/hg38/funcotator_dataSources.v1.7.20200521s.tar.gz"

    nl()
    return ref_refs

def gen_scma(conf_keys, input_df):
    base_output_dir = conf_keys['base_output_dir']
    send_email_for_all = conf_keys['send_email_for_all']
    email = conf_keys['email']

    print("Generating input for SCMA ...")
    scma_output_dir=f'{base_output_dir}/scma'
    os.makedirs(scma_output_dir, exist_ok=True)

    for index, row in input_df.iterrows():
        i = index + 1
        if send_email_for_all == False and i == input_df.size[0]:
            send_email = True
        else:
            send_email = bool(send_email_for_all)

        output = {
                "seqConvMarkAdapt.readgroup_name": row['readgroup'],
                "seqConvMarkAdapt.sample_name": row['sample_name'],
                "seqConvMarkAdapt.fastq_1": row['absolute_path_to_fq1'],
                "seqConvMarkAdapt.fastq_2": row['absolute_path_to_fq2'],
                "seqConvMarkAdapt.library_name": row['library_name'],
                "seqConvMarkAdapt.platform_unit": row['platform_unit'],
                "seqConvMarkAdapt.run_date": row['sequence_date'],
                "seqConvMarkAdapt.platform_name": row['sequence_platform'],
                "seqConvMarkAdapt.sequencing_center": row['sequence_center'],
                "seqConvMarkAdapt.make_fofn": True,
                "seqConvMarkAdapt.send_email": send_email,  
                "seqConvMarkAdapt.email": email,  
            }
        
        with open(f'{scma_output_dir}/{row["readgroup"]}.json', 'w') as outfile:
            json.dump(output, outfile, indent=4)
        output = {}

    print(f'{i} input files for SCMA saved to: {scma_output_dir}')
    nl()
    return

def gen_pon(conf_keys, input_df, ref_refs):
    base_output_dir = conf_keys['base_output_dir']
    n_dir = conf_keys['n_dir']
    gatk_docker = conf_keys['gatk_docker']
    groupname = conf_keys['groupname']
    email = conf_keys['email']
    send_email_for_all = conf_keys['send_email_for_all']
    ref_version = conf_keys['ref_version']
    
    ref_fasta = ref_refs['ref_fasta']
    ref_fai = ref_refs['ref_fai']
    ref_dict = ref_refs['ref_dict']
    gnomad = ref_refs['gnomad']
    gnomad_idx = ref_refs['gnomad_idx']
    interval_loc = ref_refs['interval_loc']

    print("Generating input for Panel of Normals ...")

    pon_output_dir = f'{base_output_dir}/m2'
    os.makedirs(pon_output_dir, exist_ok=True)

    n = input_df.query('sample_type == "N"')
    samples_n = n['sample_name'].sort_values().unique().tolist()
    n_bams = [f'{n_dir}/{n}.{ref_version}.bam' for n in samples_n]
    n_bais = [f'{n_dir}/{n}.{ref_version}.bai' for n in samples_n]

    input = {
        "Mutect2_Panel.gatk_docker": gatk_docker,

        "Mutect2_Panel.pon_name": f"{groupname}_pon",
        "Mutect2_Panel.normal_bams": n_bams,
        "Mutect2_Panel.normal_bais": n_bais,


        "Mutect2_Panel.ref_fasta": ref_fasta,
        "Mutect2_Panel.ref_fai": ref_fai,
        "Mutect2_Panel.ref_dict": ref_dict,
        "Mutect2_Panel.scatter_count": 1,
        
        "Mutect2_Panel.gnomad": gnomad,
        "Mutect2_Panel.gnomad_idx": gnomad_idx,

        "Mutect2_Panel.intervals":interval_loc,
        "Mutect2_Panel.email": email,
        "Mutect2_Panel.Mutect2.filter_mem": 2000,
        "Mutect2_Panel.send_email": True if send_email_for_all else False
    }

    with open(f'{pon_output_dir}/pon.json', 'w') as f:
        json.dump(input, f, indent=4)

    print('PoN input saved to:')
    print(f'{pon_output_dir}/pon.json')
    nl()
    return

def gen_m2(conf_keys, input_df, ref_refs):
    base_output_dir = conf_keys['base_output_dir']
    n_dir = conf_keys['n_dir']
    t_dir = conf_keys['t_dir']
    gatk_docker = conf_keys['gatk_docker']
    email = conf_keys['email']
    ref_version = conf_keys['ref_version']
    
    ref_fasta = ref_refs['ref_fasta']
    ref_fai = ref_refs['ref_fai']
    ref_dict = ref_refs['ref_dict']
    gnomad = ref_refs['gnomad']
    gnomad_idx = ref_refs['gnomad_idx']
    interval_loc = ref_refs['interval_loc']    
    pon = ref_refs['pon']    
    pon_idx = ref_refs['pon_idx']    
    funco_data_source = ref_refs['funco_data_source']    
    variants_for_contamination = ref_refs['variants_for_contamination']    
    variants_for_contamination_idx = ref_refs['variants_for_contamination_idx']    

    print("Generating input for m2 ...")
    m2_output_dir = f'{base_output_dir}/m2'

    i = 0
    os.makedirs(m2_output_dir, exist_ok=True)

    # get list of subject ids
    subject_ids = input_df["subject_id"].unique()
    t = input_df.query('sample_type == "T"')
    n = input_df.query('sample_type == "N"')

    # parse through list and get tumor and normal sample id for each one
    for s in subject_ids:
        i+= 1
        
        # this just attaches a send email job upon completion of the last workflow in the group
        send_email = True if i == len(subject_ids) else False
        # send_email = True
        
        n_sample = n.query(f'subject_id == "{s}" ')["sample_name"].values[0]
        t_sample = t.query(f'subject_id == "{s}" ')["sample_name"].values[0]
        m2_input = {
            
            "Mutect2.normal_reads": f"{n_dir}/{n_sample}.{ref_version}.bam",
            "Mutect2.normal_reads_index": f"{n_dir}/{n_sample}.{ref_version}.bai",
            "Mutect2.tumor_reads": f"{t_dir}/{t_sample}.{ref_version}.bam",
            "Mutect2.tumor_reads_index": f"{t_dir}/{t_sample}.{ref_version}.bai",
            
            "Mutect2.gatk_docker": gatk_docker,
    
            "Mutect2.intervals": interval_loc,
            "Mutect2.scatter_count": 24,
            "Mutect2.m2_extra_args": " -ip 100 ",
            "Mutect2.split_intervals_extra_args": " --subdivision-mode BALANCING_WITHOUT_INTERVAL_SUBDIVISION --dont-mix-contigs --min-contig-size 1000000 ",

            "Mutect2.filter_funcotations": "True",
            "Mutect2.funco_reference_version": "hg19" if ref_version == "b37" else ref_version, 
            # funcotator sources for all references are in here
            "Mutect2.funco_data_sources_tar_gz": funco_data_source,

            "Mutect2.ref_fasta": ref_fasta, 
            "Mutect2.ref_fai": ref_fai, 
            "Mutect2.ref_dict": ref_dict, 

            "Mutect2.pon": pon, 
            "Mutect2.pon_idx": pon_idx, 

            "Mutect2.gnomad": gnomad, 
            "Mutect2.gnomad_idx": gnomad_idx, 
            "Mutect2.variants_for_contamination": variants_for_contamination, 
            "Mutect2.variants_for_contamination_idx": variants_for_contamination_idx, 

            "Mutect2.run_funcotator": True,
            "Mutect2.run_orientation_bias_mixture_model_filter": True,
            "Mutect2.send_email": send_email,
            "Mutect2.email": email,
        }
        with open(f'{m2_output_dir}/{s}.json', 'w') as f:
            json.dump(m2_input, f, indent=4)
    print(f'{i} input JSON saved to:')
    print(f'{m2_output_dir}')
    nl()
    return

def main():
    parser = argparse.ArgumentParser(description="Generates inputs for Deng Lab's implementation of GATK DNAseq best practices", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("config_ini", help="Absolute path to config.ini")
    args = parser.parse_args()
    config = vars(args)
    conf_ini = config['config_ini']

    conf_keys = load_config(conf_ini)
    input_df = load_inputcsv(conf_keys['input_file'])
    print("=== INPUT GEN START ===")
    nl()
    ref_refs = def_refs(conf_keys)
    gen_scma(conf_keys, input_df)
    gen_pon(conf_keys, input_df, ref_refs)
    gen_m2(conf_keys, input_df, ref_refs)
    print("=== INPUT GEN END ===")

if __name__ == "__main__":
    main()