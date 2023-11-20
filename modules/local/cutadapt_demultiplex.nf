process CUTADAPT_DEMULTIPLEX {
    tag "$meta.runid"
    label 'process_single'

    publishDir "$params.outdir", pattern: '*.fastq.gz', mode: 'copy'
    
    input:
    tuple val(meta), path(key), path(fastq)

    output:
    // could run these channels into fastqc
    //tuple val(meta), path('*.fastq.gz')         , emit: reads
    path('*.fastq.gz')         , emit: reads
    tuple val(meta), path('*.log')          , emit: log
    //path('unknown*.fastq.gz')  , emit: unknown
    path "versions.yml"                         , emit: versions

    script:
    def runid = task.ext.runid ?: "${meta.runid}"
    def lane = task.ext.lane ?: "${meta.lane}"
    
    """

    cutadapt \\
        -j 2 \\
        -g file:${key} \\
        -o {name}_${runid}_${lane}.fastq.gz \\
        ${fastq} \\
        > ${runid}_${lane}.cutadapt.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt: \$(cutadapt --version 2>&1)
    END_VERSIONS
    """
}