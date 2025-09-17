#!/bin/bash

### Author ###           
# Dr. Rahadian Pratama
# Department of Biochemistry
# Faculty of Mathematic and Natural Sciences
# IPB University
# email: rahadian@apps.ipb.ac.id
######

##### script to to download  Illumina raw reads from bioproject prjna315192
### script start

## create folder 'fastq' to store all raw reads
mkdir fastq

## download reads
cd fastq
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR417/007/SRR4178797/SRR4178797_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR417/007/SRR4178797/SRR4178797_2.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR728/002/SRR7286262/SRR7286262_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR728/002/SRR7286262/SRR7286262_2.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR374/006/SRR3742286/SRR3742286_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR374/006/SRR3742286/SRR3742286_2.fastq.gz

## create list of sample for analysis
ls -1 *_1.fastq.gz | sed 's/_1.fastq.gz//' > ../sample
cd ..

### script finished
