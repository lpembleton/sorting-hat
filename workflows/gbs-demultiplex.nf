/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// print parameters

// Check mandatory parameters
if (params.input) { csv_file = file(params.input) } else { exit 1, 'Input keyfile not provided!' }

log.info """\
    ======================================================================
    S O R T   H A T
    F A S T Q C   -   D E M U L T I P L E X I N G   P I P E L I N E
    ======================================================================
    Input keyfile: ${params.input}
    Output directory: ${params.outdir}
    ======================================================================
    """
    .stripIndent()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CUTADAPT_DEMULTIPLEX } from '../modules/local/cutadapt_demultiplex'
include { CUTADAPT_TRIMMING } from '../modules/local/cutadapt_trimming'
include { AWK_PREPAREKEYFILE } from '../modules/local/awk_preparekeyfile'
include { FASTP } from '../modules/local/fastp'
include { FASTQC } from '../modules/local/fastqc'
include { MULTIQC } from '../modules/local/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/local/custom/custom_dumpsoftwareversions'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow GBS_DEMULTIPLEX {
    versions = Channel.empty()
    reports = Channel.empty()


    input_sample = extract_keyfile(file(csv_file))
    AWK_PREPAREKEYFILE(input_sample)

    CUTADAPT_TRIMMING(AWK_PREPAREKEYFILE.out.fa_samplesheet)
    versions = versions.mix(CUTADAPT_TRIMMING.out.versions)
    reports = reports.mix(CUTADAPT_TRIMMING.out.log.collect{ meta, log -> log })

    //CUTADAPT_DEMULTIPLEX(AWK_PREPAREKEYFILE.out.fa_samplesheet)
    CUTADAPT_DEMULTIPLEX(CUTADAPT_TRIMMING.out.fastq)
    // Gather used softwares versions and reports
    versions = versions.mix(CUTADAPT_DEMULTIPLEX.out.versions)
    reports = reports.mix(CUTADAPT_DEMULTIPLEX.out.log.collect{ meta, log -> log })




    // TODO: add cutadapt reports back into multiqc summary

    demulti_reads = CUTADAPT_DEMULTIPLEX.out.reads.flatten() | map { reads -> tuple(reads.baseName, reads) }
                                             | map { id, reads -> 
                                                  (sample, runid, lane) = id.tokenize("_")
                                                  meta = [id:sample, runid:runid, lane:lane, seq_type:'single']
                                                  [meta, reads]
                                                  }

    
    // Read quality and adapter trimming
    FASTP(demulti_reads)
    // Gather used softwares versions and reports
    versions = versions.mix(FASTP.out.versions)
    reports = reports.mix(FASTP.out.json.collect{ meta, json -> json })
    reports = reports.mix(FASTP.out.html.collect{ meta, html -> html })

    // QC on trimmed reads
    FASTQC(FASTP.out.reads)
    // Gather used softwares versions and reports
    versions = versions.mix(FASTQC.out.versions)
    reports = reports.mix(FASTQC.out.zip.collect{ meta, logs -> logs })
 

    // MultiQC reporting
    version_yaml = Channel.empty()
    CUSTOM_DUMPSOFTWAREVERSIONS(versions.unique().collectFile(name: 'collated_versions.yml'))
    version_yaml = CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect()

    multiqc_files = Channel.empty()
    multiqc_files = multiqc_files.mix(version_yaml)
    multiqc_files = multiqc_files.mix(reports.collect().ifEmpty([]))

    MULTIQC(multiqc_files.collect())

    multiqc_report = MULTIQC.out.report.toList()
    versions = versions.mix(MULTIQC.out.versions)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Function for input csv samples sheet generating meta fields and file paths
def extract_keyfile(csv_file) {

    Channel.of(csv_file).splitCsv(header: true)
        .map{row ->

            def meta = [:]

            if (row.runid)  meta.runid  = row.runid.toString()
            if (row.lane)  meta.lane  = row.lane.toString()

            def key         = file(row.key, checkIfExists: true)
            def fastq_1     = file(row.fastq_1, checkIfExists: true)

            return [meta, key, fastq_1 ]
            
        }

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
