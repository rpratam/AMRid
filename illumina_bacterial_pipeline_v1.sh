#!/bin/bash

### Author ###           
# Dr. Rahadian Pratama
# Department of Biochemistry
# Faculty of Mathematic and Natural Sciences
# IPB University
# email: rahadian@apps.ipb.ac.id
# Simple improved version
######

# Configuration
LOG_FILE="Enterobacter_WGS.log"
THREADS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")

# Setup logging
exec > >(tee -a "$LOG_FILE") 2>&1 

# Simple logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if required tools exist
check_tools() {
    local tools=("seqkit" "fastp" "multiqc" "shovill" "quast.py" "checkm" "abricate" "hamronize" "mlst" "parallel")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR: $tool not found. Please install it."
            exit 1
        fi
    done
    log "All required tools found"
}

# Check input files
check_inputs() {
    if [[ ! -f "sample" ]]; then
        log "ERROR: 'sample' file not found"
        exit 1
    fi
    
    if [[ ! -d "fastq" ]]; then
        log "ERROR: 'fastq' directory not found"
        exit 1
    fi
    
    # Check if fastq files exist for each sample
    while read -r sample; do
        [[ -z "$sample" ]] && continue
        if [[ ! -f "fastq/${sample}_1.fastq.gz" ]] || [[ ! -f "fastq/${sample}_2.fastq.gz" ]]; then
            log "ERROR: Missing fastq files for sample: $sample"
            exit 1
        fi
    done < sample
    
    log "All input files found"
}

log ' '
log '=================================================='
log 'Enterobacter WGS Analysis Pipeline'
log 'Dr. Rahadian Pratama - rahadian@apps.ipb.ac.id'
log "Started at: $(date)"
log "Using $THREADS CPU threads"
log '=================================================='

# Check requirements
check_tools
check_inputs

## Quality Control
log ' '
log '### Quality Control ###'
mkdir -p QC

log 'Running seqkit statistics...'
seqkit stats fastq/*.fastq.gz -T -b -a -j "$THREADS" | csvtk pretty -t > QC/raw_fastq.stats

log 'Running fastp quality filtering...'
parallel -j 4 -a sample 'fastp -i fastq/{}_1.fastq.gz -I fastq/{}_2.fastq.gz -o QC/{}_R1.fastq.gz -O QC/{}_R2.fastq.gz -h QC/{}_fastp.html -j QC/{}_fastp.json --unpaired1 QC/{}_unpaired1.fastq.gz --unpaired2 QC/{}_unpaired2.fastq.gz -q 20 -l 100 -c -w 5 --detect_adapter_for_pe -D -R "{} quality report"'

log 'Generating MultiQC report...'
multiqc --outdir QC/ --module fastp --fn_as_s_name -i "Quality Check" -f -ip -k tsv --clean-up QC/

## Assembly
log ' '
log '### Assembly ###'
mkdir -p assembly

log 'Running shovill assembly...'
parallel -j 2 -a sample 'shovill --R1 QC/{}_R1.fastq.gz --R2 QC/{}_R2.fastq.gz --depth 100 --gsize 5M --cpus 10 --ram 50 --outdir assembly/{}'

log 'Organizing assembly files...'
parallel -j 5 -a sample 'mv assembly/{}/contigs.fa assembly/{}_contigs.fa && mv assembly/{}/contigs.gfa assembly/{}_contigs.gfa && mv assembly/{}/shovill.log assembly/{}_shovill.log'
parallel -j 5 -a sample 'rm -rf assembly/{}'

## Assembly Evaluation
log ' '
log '### Assembly Evaluation ###'
mkdir -p assembly_stat

log 'Running QUAST evaluation...'
parallel -j 4 -a sample 'quast.py -t 5 -o assembly_stat/{} assembly/{}_contigs.fa'
multiqc --outdir assembly_stat -m quast -f -i "Assembly stats" --interactive assembly_stat/

log 'Running CheckM completeness check...'
checkm lineage_wf -x fa -t "$THREADS" -f assembly_stat/checkm_report.txt --tab_table assembly/ assembly_stat/ 

## AMR Annotation
log ' '
log '### AMR Annotation ###'
mkdir -p AMR

log 'Running abricate AMR annotation...'
abricate --nopath --threads "$THREADS" --db ncbi assembly/*_contigs.fa > AMR/ncbi.txt
abricate --nopath --threads "$THREADS" --db megares assembly/*_contigs.fa > AMR/megares.txt
abricate --nopath --threads "$THREADS" --db plasmidfinder assembly/*_contigs.fa > AMR/plasmidfinder.txt
abricate --nopath --threads "$THREADS" --db vfdb assembly/*_contigs.fa > AMR/vfdb.txt
abricate --nopath --threads "$THREADS" --db card assembly/*_contigs.fa > AMR/card.txt
abricate --nopath --threads "$THREADS" --db resfinder assembly/*_contigs.fa > AMR/resfinder.txt

## hAMRonize
log ' '
log '### AMR Results Harmonization ###'
VERSION_DATE=$(date '+%d.%m.%Y')

log 'Running hAMRonize...'
hamronize abricate AMR/card.txt --reference_database_version "$VERSION_DATE" --analysis_software_version 1.0.1 --format tsv --output AMR/abricate.card
hamronize abricate AMR/megares.txt --reference_database_version "$VERSION_DATE" --analysis_software_version 1.0.1 --format tsv --output AMR/abricate.megares
hamronize abricate AMR/ncbi.txt --reference_database_version "$VERSION_DATE" --analysis_software_version 1.0.1 --format tsv --output AMR/abricate.ncbi
hamronize abricate AMR/resfinder.txt --reference_database_version "$VERSION_DATE" --analysis_software_version 1.0.1 --format tsv --output AMR/abricate.resfinder

hamronize summarize -o AMR/hamronize.html -t interactive AMR/abricate.card AMR/abricate.megares AMR/abricate.ncbi AMR/abricate.resfinder

## MLST Annotation
log ' '
log '### MLST Annotation ###'
mkdir -p mlst

log 'Running MLST annotation...'
mlst --nopath --threads 4 assembly/*.fa > mlst/ST.txt

## General Annotation
log ' '
log '### General Annotation ###'
mkdir -p annotation

log 'Running prokka annotation...'
parallel -j 2 -a sample 'prokka --cpus 10 --outdir annotation/{} --force --prefix {} --addgenes --addmrna assembly/{}_contigs.fa'

## Collect All Results
log ' '
log '### Collecting All Results ###'
mkdir -p Results

# Copy analysis folders
mv QC Results/
mv assembly Results/
mv assembly_stat Results/
mv AMR Results/
mv mlst Results/
mv annotation Results/

# Copy specific reports to Results root for easy access
cp -R Results/QC/Quality-Check_multiqc_report* Results/ 2>/dev/null || log "Warning: QC report not found"
cp Results/QC/raw_fastq.stats Results/
cp -R Results/assembly_stat/Assembly-stats_multiqc_report* Results/ 2>/dev/null || log "Warning: Assembly report not found"
cp Results/assembly_stat/checkm_report.txt Results/
cp Results/AMR/hamronize.html Results/
cp Results/mlst/ST.txt Results/

# Create simple summary
echo "Pipeline completed on $(date)" > Results/summary.txt
echo "Total samples: $(wc -l < sample)" >> Results/summary.txt
echo "Log file: $LOG_FILE" >> Results/summary.txt

log ' '
log '=================================================='
log "Pipeline completed successfully at: $(date)"
log "Runtime: $SECONDS seconds"
log "All results are in the 'Results' directory"
log "Have a good day :-)"
log '=================================================='
