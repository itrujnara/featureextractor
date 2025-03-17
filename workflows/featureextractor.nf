/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_featureextractor_pipeline'

include { GAWK as EXTRACT_FEATURES } from '../modules/nf-core/gawk'
include { BEDTOOLS_SLOP            } from '../modules/nf-core/bedtools/slop'
include { BEDTOOLS_GETFASTA        } from '../modules/nf-core/bedtools/getfasta'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FEATUREEXTRACTOR {

    take:
    ch_samplesheet // channel: (meta, fasta, gff)

    main:

    ch_versions = Channel.empty()

    ch_samplesheet
        .map { meta, _fasta, gff -> [meta, gff] }
        .set { ch_gff }

    EXTRACT_FEATURES(ch_gff, [], false)

    ch_versions
        .mix(EXTRACT_FEATURES.out.versions)
        .set { ch_versions }

    BEDTOOLS_SLOP(EXTRACT_FEATURES.out.output, file(params.sizes))

    ch_versions
        .mix(BEDTOOLS_SLOP.out.versions)
        .set { ch_versions }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'featureextractor_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
