#!/bin/bash

while getopts i:g: flag
do
    case "${flag}" in
        # the inputlist to read from
        i) inputlist=${OPTARG};; 
    esac
done

cat ${inputlist} | xargs -I % bash -c 'echo $(cat %_1.fastq | wc -l)/4 | bc && echo $(cat %_2.fastq | wc -l)/4 | bc'