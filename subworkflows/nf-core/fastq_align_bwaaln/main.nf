//
// Alignment with bwa aln and sort
//

include { BWA_ALN            } from '../../../modules/nf-core/bwa/aln/main'
include { BWA_SAMSE          } from '../../../modules/nf-core/bwa/samse/main'
include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_FASTA     } from '../../../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/samtools_fasta'                                                                                                     


workflow FASTQ_ALIGN_BWAALN {

    take:
    ch_reads // channel (mandatory): [ val(meta), path(reads) ]. subworkImportant: meta REQUIRES single_end` entry!
    ch_index // channel (mandatory): [ val(meta), path(index) ]

    main:


    // Alignment
    BWA_ALN ( ch_reads, ch_index )

    ch_sai_for_bam = ch_reads
        .join ( BWA_ALN.out.sai )

    // SAI to BAM
    BWA_SAMSE ( ch_sai_for_bam, ch_index )

    // BAM to FASTA
    SAMTOOLS_FASTA ( BWA_SAMSE.out.bam )

    // Remove superfluous internal maps to minimise clutter as much as possible
    //ch_bam_for_emit = ch_bam_for_index.map{ meta, bam -> [meta - meta.subMap('key_read_ref'), bam] }
    //ch_index_for_emit = SAMTOOLS_INDEX.out.index.map{ meta, index -> [meta - meta.subMap('key_read_ref'), index] }

    emit:
    bam        = BWA_SAMSE.out.bam
    fasta      = SAMTOOLS_FASTA.out.fasta
    // Note: output channels will contain meta with additional 'id_index' meta
    // value to allow association of BAM file with the meta.id of input indicies
    //bam      = ch_bam_for_emit     // channel: [ val(meta), path(bam) ]
    //index    = ch_index_for_emit     // channel: [ val(meta), path(bai) ]
}

