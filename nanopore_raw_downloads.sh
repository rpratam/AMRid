#!/bin/bash

### Author ###           
# Dr. Rahadian Pratama
# Department of Biochemistry
# Faculty of Mathematic and Natural Sciences
# IPB University
# email: rahadian@apps.ipb.ac.id
######

##### script to to download  Nanopore raw reads from bioproject prjna315192
### script start

## create folder 'fastq' to store all raw reads
mkdir fastq

## download reads
cd fastq

wget -O SRR17645345.fastq.gz ftp.sra.ebi.ac.uk/vol1/fastq/SRR176/045/SRR17645345/SRR17645345_1.fastq.gz
wget -O SRR24451070.fastq.gz ftp.sra.ebi.ac.uk/vol1/fastq/SRR244/070/SRR24451070/SRR24451070_1.fastq.gz
wget -O SRR9987849.fastq.gz ftp.sra.ebi.ac.uk/vol1/fastq/SRR998/009/SRR9987849/SRR9987849_1.fastq.gz

## create list of sample for analysis
ls -1 *.fastq.gz | sed 's/.fastq.gz//' > ../sample
cd ..
### script finished
