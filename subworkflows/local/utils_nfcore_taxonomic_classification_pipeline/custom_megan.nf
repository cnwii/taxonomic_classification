process CUSTOM_MEGAN {

    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::megan=6.25.9 bioconda::blast=2.17.0"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta2), path(blastn_db)
    tuple val(meta3), path(db)
    path(a2t)

    output:
    tuple val(meta), path("*.rma6"), emit: rma6

    script:
    def blastn_args = task.ext.blastn_args ?: ''
    def megan_args = task.ext.megan_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getExtension() == "gz" ? true : false
    def fasta_name = is_compressed ? fasta.getBaseName() : fasta

    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    export BLASTDB=${blastn_db}

    DB=`find -L ./ -name "*.nal" | sed 's/\\.nal\$//'`
    if [ -z "\$DB" ]; then
        DB=`find -L ./ -name "*.nin" | sed 's/\\.nin\$//'`
    fi
    echo Using \$DB

        blastn \\
        -db \$DB \\
        -query ${fasta_name} \\
        -out ${prefix}.tab \\
        -outfmt "6 qseqid saccver pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids"

        blast2rma \\
        ${megan_args} \\
        -i ${prefix}.tab \\
        -f BlastTab \\
        -bm BlastN \\
        -a2t ${a2t} \\
        -r ${db} \\
        --out ${prefix}.rma6

    """
}