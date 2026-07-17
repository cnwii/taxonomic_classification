process RMA6_TO_FASTA {

    tag "$meta.id"
    label 'process_single'

    conda "bioconda::megan=6.25.9"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megan:6.25.9--h9ee0642_0':
        'quay.io/biocontainers/megan:6.25.9--h9ee0642_0' }"

    input:
    tuple val(meta), path(rma6)
    path(tax_id)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    base=\$(basename ${rma6} .rma6)

    echo "Processing \$base..."

    for taxon in ${tax_id}; do
    outname=\$(echo "\$taxon" | tr '[:upper:]' '[:lower:]')

    read-extractor \
        -i ${rma6} \
        -o "\${base}_\${outname}.fasta" \
        -c Taxonomy \
        -n "\$taxon" \
        --allBelow \
        -v

    done
    """
}