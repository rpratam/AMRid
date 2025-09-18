Preparing script for testing WGS pipeline
1. Miniconda installation
Follow tutorial below for different OS
 a. for Linux: https://docs.conda.io/projects/conda/en/stable/user-guide/install/linux.html
 b. for MacOS: https://docs.conda.io/projects/conda/en/stable/user-guide/install/macos.html
 
2. Setup bioconda channel
Before start working with conda, the bioconda channel need to be set up. Open new terminal after installing miniconda, then input these commands:
```
conda config --add channels bioconda
conda config --add channels conda-forge
```

3. Create new environment specific for Illumina and ont sequencing reads analysis
 a. for illumina reads processing pipeline, execute command below: 
```
conda create -n illumina falco fastp seqkit csvtk spades shovill abricate hamronization mlst checkm-genome quast prokka bakta multiqc
```

the command above will create new conda environment named ‘illumina’ that contain tools:
- raw reads QC and filtering: falco, seqkit and fastp
- assembly: spades and shovill
- assembly evaluation: quast and checkm
- annotation: prokka and bakta
- sequence typing: mlst
- antimicrobial screening: abricate

 b. for oxford nanopore technologies pipeline, execute the command below:
```
conda create -n ont nanoplot seqkit csvtk flye abricate mlst hamronization checkm-genome quast prokka bakta multiqc
```

the command above will create new conda environment named ‘ont’ that contain tools:
- raw reads QC: nanoplot and seqkit
- assembly: flye
- assembly evaluation: quast and checkm
- annotation: prokka and bakta
- sequence typing: mlst
- antimicrobial screening: abricate

4. Prepare raw reads for each platform analysis
  public raw reads from study PRJNA315192 will be used in this pipeline. to download them, fetch and run script:
  
- Illumina: illumina_raw_downloads.sh
- Nanopore: nanopore_raw_downloads.sh

it is advised to create separate folder for testing illumina and nanopore pipeline, then put each of the script above to respective folder.

5. Testing analysis pipeline for each platform
Running pipeline analysis for Illumina raw reads as well nanopore raw reads is simply to execute one script below:
- Illumina: illumina_bacterial_pipeline_v1.sh
- Nanopore: nanopore_bacterial_pipeline_v1.sh

Put the script above in the same folder where you put the script to download raw reads above, for Illumina and Nanopore respectively.
