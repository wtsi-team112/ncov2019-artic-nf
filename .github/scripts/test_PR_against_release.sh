#!/bin/bash
set -eo pipefail
export PATH=/opt/conda/bin:$PATH

# write log as github Action artifact
mkdir artifacts
echo run in illumina mode with defaults >> artifacts/test_artifact.log

# run current pull request code
singularity --version
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile singularity \
       --directory $PWD/.github/data/fastqs/ \
       --illumina \
       --prefix test
cp .nextflow.log artifacts/
# save work dir and results for following tests
cp -r results results_singularity_profile
cp -r work work_singularity_profile

# run tests against previous previous_release to compare outputs 
git clone https://github.com/wtsi-team112/ncov2019-artic-nf.git previous_release 
cd previous_release
git checkout 42a79999f11304671b9d22e4959b0167b2130944 
# the github runner only has 2 cpus available, so replace for that commit required:
sed -i s'/cpus = 4/cpus = 2/'g conf/resources.config
ln -s ../*.sif ./
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile singularity \
       --directory $PWD/../.github/data/fastqs/ \
       --illumina \
       --prefix test
cp .nextflow.log ../artifacts/previous_release.nextflow.log
cd ..

# exclude files from comparison
# and list differences
find results ./previous_release/results \
     -name "test.qc.csv" \
     -o -name "*.fq.gz" \
     -o -name "*.bam" \
     -o -name "scheme" | xargs rm -rf
git diff --stat --no-index results ./previous_release/results > diffs.txt
if [ -s diffs.txt ]
then
  echo differences found between pull request and previous release
  cp diffs.txt artifacts/  
  exit 1
else
  echo no differences found between pull request and previous release
fi

# clean-up for following tests
rm -rf previous_release && rm -rf results && rm -rf work && rm -rf .nextflow*
