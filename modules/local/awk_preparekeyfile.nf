process AWK_PREPAREKEYFILE {
    tag "$meta.runid"
    label 'process_single'

    input:
    tuple val(meta), path(key), path(fastq)

    output:
    tuple val(meta), path('*.fasta'), path(fastq), emit: fa_samplesheet
    
    shell:
    """

    awk '{if (NR!=1) {print}}' ${key} | awk -F'\t' -v OFS='\n' '{\$1 = ">" \$1} 1' > key.fasta

    """
}