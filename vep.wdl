version 1.0

workflow VEP {
    input {
        File vcf
        File refFasta
        File refFastaIndex
        File cache
        String outputPrefix
        File pluginCADDSNV
        File pluginCADDSNVIndex
        File pluginCADDInDel
        File pluginCADDInDelIndex
        File pluginSpliceAISNV
        File pluginSpliceAISNVIndex
        File pluginSpliceAIIndel
        File pluginSpliceAIIndelIndex
    }

    call AnnotateVEP {
        input:
            refFasta = refFasta,
            vcf = vcf,
            refFastaIndex = refFastaIndex,
            outputPrefix = outputPrefix,
            cache = cache,
            pluginCADDSNV = pluginCADDSNV,
            pluginCADDSNVIndex = pluginCADDSNVIndex,
            pluginCADDInDel = pluginCADDInDel,
            pluginCADDInDelIndex = pluginCADDInDelIndex,
            pluginSpliceAISNV = pluginSpliceAISNV,
            pluginSpliceAISNVIndex = pluginSpliceAISNVIndex,
            pluginSpliceAIIndel = pluginSpliceAIIndel,
            pluginSpliceAIIndelIndex = pluginSpliceAIIndelIndex
    }
}

task AnnotateVEP {
    input {
        File refFasta
        File vcf
        File refFastaIndex
        String outputPrefix
        File cache
        File pluginCADDSNV
        File pluginCADDSNVIndex
        File pluginCADDInDel
        File pluginCADDInDelIndex
        File pluginSpliceAISNV
        File pluginSpliceAISNVIndex
        File pluginSpliceAIIndel
        File pluginSpliceAIIndelIndex

        String dockerImage = "ensemblorg/ensembl-vep:release_109.1"
        Float memoryGib = 30
        Int threads = 8
    }

    command <<<
        # create vep_cache folder to store decompressed VEP cache files
        mkdir -p vep_cache
        tar -x -f ~{cache} -C vep_cache

        vep \
            --input_file ~{vcf} \
            --canonical \
            --fasta ~{refFasta} \
            --force_overwrite \
            --fork ~{threads} \
            --allele_number \
            --hgvs \
            --hgvsg \
            --mane \
            --numbers \
            --no_escape \
            --protein \
            --symbol \
            --tab \
            --variant_class \
            --offline \
            --use_transcript_ref \
            --dir_cache vep_cache \
            --refseq \
            --af_gnomade \
            --af_gnomadg \
            --plugin CADD,~{pluginCADDSNV},~{pluginCADDInDel} \
            --plugin SpliceAI,snv=~{pluginSpliceAISNV},indel=~{pluginSpliceAIIndel} \
            --output_file ~{outputPrefix}.tsv
    >>>

    runtime {
        docker: dockerImage
        memory: memoryGib + " GiB"
        cpu: threads
    }

    output {
        File outputTsv = "~{outputPrefix}.tsv"
        File outputHtml = "~{outputPrefix}.tsv_summary.html"
    }

    parameter_meta {
        # inputs
        vcf: "Input VCF file for annotation with Ensembl's Variant Effect Predictor (VEP)."
        refFasta: "Human genome reference FASTA file."
        refFastaIndex: "Human genome reference FASTA file index."
        cache: "VEP cache files path."
        outputPrefix: "Prefix of output files."
        pluginCADDSNV: "CADD plugin file (SNVs)."
        pluginCADDSNVIndex: "Index for the CADD plugin file (SNVs)."
        pluginCADDInDel: "CADD plugin file (small indels)."
        pluginCADDInDelIndex: "Index for the CADD plugin file (small indels)."
        pluginSpliceAISNV: "SpliceAI plugin file (SNVs)."
        pluginSpliceAISNVIndex: "The index for the SpliceAI plugin file (SNVs)."
        pluginSpliceAIIndel: "SpliceAI plugin file (small indels)."
        pluginSpliceAIIndelIndex: "The index for the SpliceAI plugin file (small indels)."

        dockerImage: "VEP Docker image."
        memoryGib: "Memory in GB used by the VEP Docker image. Defaults to 30 GB."
        threads: "Number of threads used by VEP during annotation. Defaults to 8 threads."

        # outputs
        outputTsv: "Annotation output file in TSV format."
        outputHtml: "Annotation summary file in HTML format."

    }
}