[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)

# sorting-hat
<img align="right" src="docs/images/sorting-hat.jpg" height="100">


## Introduction

**sorting-hat** is a bioinformatics pipeline that demultiplexes restriction enzyme genotyping-by-sequencing data, performs read trimming and computes standard QA/QC stats.


## Pipeline Summary:

For Restriction Enzyme GBS Demulitplexing:
1. Prepare keyfiles for cutadapt input ([awk](https://www.gnu.org/software/gawk/manual/gawk.html))
2. Timming fastq file to remove common adapter before looking for internal barcodes in step 3. ([Cutadapt](https://cutadapt.readthedocs.io/en/stable/))
3. Demultiplex fastq file using provide barcode keys ([Cutadapt](https://cutadapt.readthedocs.io/en/stable/))
4. Read quality and adapter trimming ([fastp](https://github.com/OpenGene/fastp))
5. Read QC ([FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
6. Reporting ([MultiQC](https://multiqc.info/))

## Input Requirements:
The pipeline expects a CSV samplesheet as input, which should contain the run id, the lane number, the path to the key file and the path to the fastq file. It should like something similar to:

```csv
runid,lane,key,fastq_1
seq01,1,seq01-keyfile.txt,seq01_S2_L001_R1_001.fastq.gz
seq02,2,seq02-keyfile.txt,seq02_S3_L002_R1_001.fastq.gz
```

*Note the column names are important*

The keyfile itself should be a tab separated text file (no header) containing the sample name and the associated barcode sequence. I should look something similar to:

```text
sample01    AACT
sample02    CGGT
sample03    TGCG
```


## Usage

nextflow run main.nf --input samplesheet.csv --outdir <OUTDIR> -profile local

*If no outdir is provided it will create one called 'demultiplexed' in the associated directory.*

## Pipeline Output

This pipeline outputs demultplexed fastq files. fastq files following quality and adapter trimming are not retained as most other pipeline included this process in their initial steps. Fastp and FastQC processing in only included to generate sequence quality reports to help users determine the appropriate next steps.

## Credits

sorting-hat (the nf pipeline, not the harry potter hat) was originally written by [`LWPembleton`](https://github.com:lpembleton).

A lot of inspiration and structure was taken from the Nextflow documentation, the fantastic nf-core community and modules.

> **Nextflow enables reproducible computational workflows.**
> 
> Paolo Di Tommaso, Maria Chatzou, Evan Floden, Pablo Prieto Barja, Emilio Palumbo & Cedric Notredame.
> 
> P. Di Tommaso, et al. Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319 (2017) doi:10.1038/nbt.3820

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).



## Citations

