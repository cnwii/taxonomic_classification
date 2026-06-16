//
// Alignment with bwa aln and sort
//

include { BWA_ALN            } from '../../../modules/nf-core/bwa/aln/main'
include { BWA_SAMSE          } from '../../../modules/nf-core/bwa/samse/main'
include { BWA_SAMPE          } from '../../../modules/nf-core/bwa/sampe/main'
include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'

workflow FASTQ_ALIGN_BWAALN {

    take:
    ch_reads // channel (mandatory): [ val(meta), path(reads) ]. subworkImportant: meta REQUIRES single_end` entry!
    ch_index // channel (mandatory): [ val(meta), path(index) ]

    main:


    // Alignment and conversion to bam
    BWA_ALN ( ch_reads, ch_index )

    ch_sai_for_bam = ch_reads
                        .join ( BWA_ALN.out.sai )
                        .branch {
                            meta, reads, sai ->
                                pe: !meta.single_end
                                se: meta.single_end
                        }

    // Split as PE/SE have different SAI -> BAM commands
    ch_sai_for_bam_pe =  ch_sai_for_bam.pe
                            .join ( ch_index )
                            .multiMap {
                                meta, reads, sai, index ->
                                    reads: [ meta, reads, sai ]
                                    index: [ meta, index      ]
                            }

    ch_sai_for_bam_se =  ch_sai_for_bam.se
                            .join ( ch_index )
                            .multiMap {
                                meta, reads, sai, index ->
                                    reads: [ meta, reads, sai ]
                                    index: [ meta, index      ]
                            }


    BWA_SAMPE ( ch_sai_for_bam_pe.reads, ch_sai_for_bam_pe.index )

    BWA_SAMSE ( ch_sai_for_bam_se.reads, ch_sai_for_bam_se.index )

    ch_bam_for_index = BWA_SAMPE.out.bam.mix( BWA_SAMSE.out.bam )

    // Index all
    SAMTOOLS_INDEX ( ch_bam_for_index )

    // Remove superfluous internal maps to minimise clutter as much as possible
    ch_bam_for_emit = ch_bam_for_index.map{ meta, bam -> [meta - meta.subMap('key_read_ref'), bam] }
    ch_bai_for_emit = SAMTOOLS_INDEX.out.bai.map{ meta, bai -> [meta - meta.subMap('key_read_ref'), bai] }
    ch_csi_for_emit = SAMTOOLS_INDEX.out.csi.map{ meta, csi -> [meta - meta.subMap('key_read_ref'), csi] }

    emit:
    // Note: output channels will contain meta with additional 'id_index' meta
    // value to allow association of BAM file with the meta.id of input indicies
    bam      = ch_bam_for_emit     // channel: [ val(meta), path(bam) ]
    bai      = ch_bai_for_emit     // channel: [ val(meta), path(bai) ]
    csi      = ch_csi_for_emit     // channel: [ val(meta), path(csi) ]
}

