process CUTADAPT_TRIMMING {
    tag "$meta.runid"
    label 'process_single'
 
    input:
    tuple val(meta), path(key), path(fastq)

    output:
    tuple val(meta), path(key), path('*.fastq.gz')      , emit: fastq
    tuple val(meta), path('*.log')                      , emit: log
    path "versions.yml"                                 , emit: versions

    script:
    def runid = task.ext.runid ?: "${meta.runid}"
    def lane = task.ext.lane ?: "${meta.lane}"
    
    """

    cutadapt \\
        -j 2 \\
        -a common_adapter=AGATCGGAAGAGCGGTTCAGCAGGAATGCCGAG \\
        --minimum-length 40 \\
        -o trimmed.${fastq} \\
        ${fastq} \\
        > ${runid}_${lane}_trimming.cutadapt.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt: \$(cutadapt --version 2>&1)
    END_VERSIONS
    """
}