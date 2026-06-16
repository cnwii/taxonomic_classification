/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK           } from '../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/input_check'
include { BWA_INDEX             } from '../modules/nf-core/bwa/index/main' 
include { FASTQ_ALIGN_BWAALN    } from '../subworkflows/nf-core/fastq_align_bwaaln/main' 
include { BOWTIE2_BUILD         } from '../modules/nf-core/bowtie2/build/main' 
include { BOWTIE2_ALIGN         } from '../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_BT2 } from '../modules/nf-core/samtools/index/main'
include { BLAST_BLASTN          } from '../modules/nf-core/blast/blastn/main'
//include { SPLITBAMBYSPECIES } from '../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/split_bam_tax'
include { MALT_RUN              } from '../modules/nf-core/malt/run/main' 
include { MALTEXTRACT           } from '../modules/nf-core/maltextract/main'
include { MEGAN_RMA2INFO        } from '../modules/nf-core/megan/rma2info/main'  
include { MAPDAMAGE2            } from '../modules/nf-core/mapdamage2/main'                                                                                       

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TAXONOMIC_CLASSIFICATION {

    take:
    samplesheet 
    
    main:

    ch_meta_db = Channel.fromPath(params.meta_db_path)
    .splitCsv(header: true)
    .map { row ->
        meta = [id: row.species]
        fasta = file(row.fasta)
        tuple(meta, fasta)
    }

    INPUT_CHECK (samplesheet)

    if(!params.use_bowtie2) {
    BWA_INDEX(ch_meta_db)

    FASTQ_ALIGN_BWAALN(
        INPUT_CHECK.out.reads,
        BWA_INDEX.out.index
    )

    ch_mapped_bam = FASTQ_ALIGN_BWAALN.out.bam
        .map{
        meta, bam ->
        new_meta = meta + [ reference: meta.id_index ]
        [ new_meta, bam ]
        }

    ch_mapped_bai = params.fasta_largeref ? FASTQ_ALIGN_BWAALN.out.csi : FASTQ_ALIGN_BWAALN.out.bai

    } else {
    BOWTIE2_BUILD(ch_meta_db)

    BOWTIE2_ALIGN(
        INPUT_CHECK.out.reads,
        BOWTIE2_BUILD.out.index,
        [],
        true,
        true
    )

    ch_mapped_bam = BOWTIE2_ALIGN.out.bam

    SAMTOOLS_INDEX_BT2 ( ch_mapped_bam )
    ch_mapped_bai = params.fasta_largeref ? SAMTOOLS_INDEX_BT2.out.csi : SAMTOOLS_INDEX_BT2.out.bai

    }

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GRAVEYARD
    ch_adapter_trimmed_reads_prepped = ADNA_TRIM.out.collapsed
            .map {
                meta, reads -> 
                    def meta_new = meta.clone()
                    meta_new.single_end = true
                    [ meta_new, reads ]
            }
            .mix(ADAPTERREMOVAL_SINGLE.out.singles_truncated)

    def meta2 = [
    dbtype: 'nucl'
    ]

    ch_blastn_db = Channel.of(
    tuple(meta2, file(params.blastdb))
    )

    BLAST_BLASTN(
        
        ch_blastn_db
    )



    
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
