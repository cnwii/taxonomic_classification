process SPLITBAMBYSPECIES {

    tag "${meta.id}"
    label 'process_single'

    conda "bioconda::samtools"

    input:
    tuple prefix, file(bam), file(bai) from ch_input

    output:
    tuple prefix, wallaby, file("${prefix}_${wallaby}.bam") into ch_wallaby_bams
    tuple prefix, wallaby, file("${prefix}_${wallaby}.fasta") into ch_wallaby_fasta
    tuple prefix, rabbit, file("${prefix}_${rabbit}.bam") into ch_rabbit_bams
    tuple prefix, rabbit, file("${prefix}_${rabbit}.fasta") into ch_rabbit_fasta
    tuple prefix, human, file("${prefix}_${human}.bam") into ch_human_bams
    tuple prefix, human, file("${prefix}_${human}.fasta") into ch_human_fasta
    tuple prefix, dog, file("${prefix}_${dog}.bam") into ch_dog_bams
    tuple prefix, dog, file("${prefix}_${dog}.fasta") into ch_dog_fasta

    script:
    human = "human"
    wallaby = "wallaby"
    rabbit = "rabbit"
    dog = "dog"
    """
    # Extract reads per species
    samtools view -bh ${bam} \$(cat ${human_contig} | tr "\\n" " ") -o ${prefix}_${human}.bam
    samtools view -bh ${bam} \$(cat ${wallaby_contig} | tr "\\n" " ") -o ${prefix}_${wallaby}.bam
    samtools view -bh ${bam} \$(cat ${rabbit_contig} | tr "\\n" " ") -o ${prefix}_${rabbit}.bam
    samtools view -bh ${bam} \$(cat ${dog_contig} | tr "\\n" " ") -o ${prefix}_${dog}.bam

    # Make fasta from the bams
    samtools fasta ${prefix}_${human}.bam > ${prefix}_${human}.fasta
    samtools fasta ${prefix}_${wallaby}.bam > ${prefix}_${wallaby}.fasta
    samtools fasta ${prefix}_${rabbit}.bam > ${prefix}_${rabbit}.fasta
    samtools fasta ${prefix}_${dog}.bam > ${prefix}_${dog}.fasta
    """
}

ch_wallaby_bams.mix(ch_rabbit_bams, ch_human_bams, ch_dog_bams).into {  ch_species_bams_view ; ch_species_bam_for_extract_reads }

ch_wallaby_fasta.mix(ch_rabbit_fasta, ch_human_fasta, ch_dog_fasta).into { ch_species_fasta_for_megan ; ch_blast_input  ; ch_species_fasta_view }