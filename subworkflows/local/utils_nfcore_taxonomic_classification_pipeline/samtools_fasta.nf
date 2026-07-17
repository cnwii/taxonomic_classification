process SAMTOOLS_FASTA {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::htslib=1.23.1 bioconda::samtools=1.23.1"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c5d2818c8b9f58e1fba77ce219fdaf32087ae53e857c4a496402978af26e78c/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.23.1--5b6bb4ede7e612e5'}"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    samtools \\
        fasta \\
        ${input} > ${prefix}.fasta \\
        ${args} \\
        --threads ${task.cpus - 1}
    """
}