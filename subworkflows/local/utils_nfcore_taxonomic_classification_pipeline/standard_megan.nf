process STANDARD_MEGAN {

    tag "$meta.id"
    label 'process_low'

    conda "bioconda::megan=6.25.9"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megan:6.25.9--h9ee0642_0':
        'quay.io/biocontainers/megan:6.25.9--h9ee0642_0' }"

    input:
    tuple val(meta), path(blastn)
    tuple val(meta2), path(db)

    output:
    tuple val(meta), path("*.rma6"), emit: rma6

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    blast2rma -i ${blastn} -f BlastText -bm BlastN \\
        ${args} \\
        -r ${db} --out ${prefix}.rma6
    """
}