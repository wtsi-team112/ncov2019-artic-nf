#!/bin/bash
set -eo pipefail
export PATH=/opt/conda/bin:$PATH

echo  test --bed and --ref inputs >> artifacts/test_artifact.log

export REF_FILE=$(find work_singularity_profile | grep -v scheme | grep 'ref.fa$' | head -n1 | xargs readlink | sed s'/ncov2019-artic-nf\/work\//ncov2019-artic-nf\/work_singularity_profile\//'g)
export BED_FILE=$(find work_singularity_profile | grep -v scheme | grep 'bed$' | head -n1 | xargs readlink | sed s'/ncov2019-artic-nf\/work\//ncov2019-artic-nf\/work_singularity_profile\//'g)
echo ref file: $REF_FILE
echo bed file: $BED_FILE

# run current pull request code
singularity --version
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile singularity \
       --ref $REF_FILE \
       --bed $BED_FILE \
       --directory $PWD/.github/data/ \
       --illumina \
       --prefix test
cp .nextflow.log artifacts/ref_bed.nextflow.log

# check that git clone did not ran:
find work -name .command.sh \
    | xargs cat | grep 'git clone' \
    && exit 1 \
	|| echo "ran with --bed and --ref: did NOT use git clone" 

find results results_singularity_profile \
     -name "test.qc.csv" \
     -o -name "*.fq.gz" \
     -o -name "*.bam" \
     -o -name "scheme" | xargs rm -rf
git diff --stat --no-index results results_singularity_profile > diffs.txt
if [ -s diffs.txt ]
then
  echo differences found for pull request with or without --ref and --bed
  cp diffs.txt artifacts/diffs_bed_ref.txt  
  exit 1
else
  echo no differences found for pull request with or without --ref and --bed 
fi

# clean-up for following tests
rm -rf results && rm -rf work && rm -rf .nextflow*
