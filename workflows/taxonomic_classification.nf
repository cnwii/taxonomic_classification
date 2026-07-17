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
include { SAMTOOLS_FASTA as SAMTOOLS_FASTA_BT2 } from '../modules/nf-core/samtools/fasta/main'  
include { BLAST_BLASTN          } from '../modules/nf-core/blast/blastn/main'
include { STANDARD_MEGAN        } from '../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/standard_megan'
include { CUSTOM_MEGAN          } from '../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/custom_megan'  
include { RMA6_TO_FASTA         } from '../subworkflows/local/utils_nfcore_taxonomic_classification_pipeline/rma6_to_fasta'  
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

    // RUN BWA
    if(!params.use_bowtie2) {
    BWA_INDEX(ch_meta_db)

    FASTQ_ALIGN_BWAALN(
        INPUT_CHECK.out.reads,
        BWA_INDEX.out.index
    )

    ch_bam = FASTQ_ALIGN_BWAALN.out.bam
    ch_fasta = FASTQ_ALIGN_BWAALN.out.fasta
    
    // RUN BOWTIE2
    } else {
    BOWTIE2_BUILD(ch_meta_db)

    BOWTIE2_ALIGN(
        INPUT_CHECK.out.reads,
        BOWTIE2_BUILD.out.index,
        ch_meta_db,
        false,
        false
    )

    SAMTOOLS_FASTA_BT2 ( BOWTIE2_ALIGN.out.bam, false )
    ch_bam = BOWTIE2_ALIGN.out.bam
    ch_fasta = SAMTOOLS_FASTA_BT2.out.fasta
    }

    def meta2 = [
    dbtype: 'nucl'
    ]

    ch_blastn_db = Channel.of(
    tuple(meta2, file(params.blastdb))
    )

    if(!params.custom_megan) {
    BLAST_BLASTN(
        ch_fasta,
        ch_blastn_db,
        [],
        false,
        false
    )

    STANDARD_MEGAN(
        BLAST_BLASTN.out.txt,
        ch_meta_db
    )

    ch_rma6 = STANDARD_MEGAN.out.rma6

    } else {

    Channel
    .fromPath(params.a2t_map)
    .set { ch_a2t_map }

    CUSTOM_MEGAN(
        ch_fasta,
        ch_blastn_db,
        ch_meta_db,
        ch_a2t_map
    )

    ch_rma6 = CUSTOM_MEGAN.out.rma6
    }

    ch_tax_id = Channel.fromPath(params.meta_db_path)
    .splitCsv(header: true)
    .map { row ->
        tax_id = file(row.tax_id)
    }

    RMA6_TO_FASTA(
        ch_rma6,
        ch_tax_id
    )

    ch_megan_fasta = RMA6_TO_FASTA.out.fasta
        .map { meta, fasta ->
        fasta
        }

    MAPDAMAGE2(
        ch_bam,
        ch_megan_fasta
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GRAVEYARD
    

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
